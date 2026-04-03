// Supabase Edge Function: check-geofence
// Called by the mobile app when user location changes significantly
// Checks if user is within any active geofence and triggers notifications

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface LocationPayload {
  latitude: number;
  longitude: number;
  user_id: string;
}

Deno.serve(async (req: Request) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { latitude, longitude, user_id }: LocationPayload = await req.json();

    if (!latitude || !longitude || !user_id) {
      return new Response(
        JSON.stringify({ error: "Missing latitude, longitude, or user_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get user's notification preferences
    const { data: profile } = await supabase
      .from("profiles")
      .select("max_daily_notifications, preferred_categories, push_token, device_platform")
      .eq("id", user_id)
      .single();

    if (!profile?.push_token) {
      return new Response(
        JSON.stringify({ triggered: 0, reason: "no_push_token" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Find nearby active promotions using PostGIS
    const { data: nearbyPromotions, error } = await supabase.rpc(
      "get_nearby_promotions",
      {
        user_lat: latitude,
        user_lng: longitude,
        radius_meters: 5000, // Check within 5km max
      }
    );

    if (error) throw error;

    let triggered = 0;
    const maxDaily = profile.max_daily_notifications ?? 2;

    for (const promo of nearbyPromotions ?? []) {
      // Check if user is within THIS business's specific geofence radius
      if (promo.distance_meters > promo.geofence_radius) continue;

      // Check time-based rules
      if (promo.active_time_start && promo.active_time_end) {
        const now = new Date();
        const currentTime = `${now.getHours().toString().padStart(2, "0")}:${now.getMinutes().toString().padLeft(2, "0")}`;
        if (currentTime < promo.active_time_start || currentTime > promo.active_time_end) {
          continue;
        }
      }

      // Check cooldown and frequency cap
      const { data: canSend } = await supabase.rpc("can_send_notification", {
        p_consumer_id: user_id,
        p_business_id: promo.business_id,
        p_cooldown_hours: 24,
        p_daily_limit: maxDaily,
      });

      if (!canSend) continue;

      // Send push notification
      const notificationTitle = `${promo.business_name} near you!`;
      const notificationBody = promo.title;

      // Log the notification
      await supabase.from("notification_log").insert({
        consumer_id: user_id,
        business_id: promo.business_id,
        promotion_id: promo.promotion_id,
        title: notificationTitle,
        body: notificationBody,
        trigger_latitude: latitude,
        trigger_longitude: longitude,
        distance_meters: promo.distance_meters,
      });

      // Update cooldown
      await supabase.from("notification_cooldowns").upsert(
        {
          consumer_id: user_id,
          business_id: promo.business_id,
          last_notified_at: new Date().toISOString(),
        },
        { onConflict: "consumer_id,business_id" }
      );

      // Log analytics
      await supabase.from("analytics_events").insert({
        business_id: promo.business_id,
        event_type: "notification_sent",
        promotion_id: promo.promotion_id,
        consumer_id: user_id,
        metadata: {
          distance: promo.distance_meters,
          lat: latitude,
          lng: longitude,
        },
      });

      // Send via FCM (call send-notification function)
      await supabase.functions.invoke("send-notification", {
        body: {
          token: profile.push_token,
          platform: profile.device_platform,
          title: notificationTitle,
          body: notificationBody,
          data: {
            promotion_id: promo.promotion_id,
            business_id: promo.business_id,
          },
        },
      });

      triggered++;

      // Respect daily limit
      if (triggered >= maxDaily) break;
    }

    return new Response(
      JSON.stringify({ triggered, checked: nearbyPromotions?.length ?? 0 }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
