// Supabase Edge Function: send-notification
// Sends push notifications via FCM (Firebase Cloud Messaging)

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface NotificationPayload {
  token: string;
  platform: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { token, platform, title, body, data }: NotificationPayload =
      await req.json();

    if (!token || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing token, title, or body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const fcmKey = Deno.env.get("FCM_SERVER_KEY");
    if (!fcmKey) {
      return new Response(
        JSON.stringify({ error: "FCM_SERVER_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build FCM payload
    const fcmPayload: Record<string, any> = {
      to: token,
      notification: {
        title,
        body,
        sound: "default",
        badge: 1,
      },
      data: {
        ...data,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    // Platform-specific config
    if (platform === "android") {
      fcmPayload.android = {
        priority: "high",
        notification: {
          channel_id: "promofy_promotions",
          color: "#6C5CE7",
          icon: "ic_notification",
        },
      };
    } else if (platform === "ios") {
      fcmPayload.apns = {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            "content-available": 1,
          },
        },
      };
    }

    // Send via FCM HTTP v1 API
    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${fcmKey}`,
      },
      body: JSON.stringify(fcmPayload),
    });

    const result = await response.json();

    if (!response.ok) {
      throw new Error(`FCM error: ${JSON.stringify(result)}`);
    }

    return new Response(
      JSON.stringify({ success: true, fcm_result: result }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
