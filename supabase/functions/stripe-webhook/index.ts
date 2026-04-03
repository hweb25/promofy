// Supabase Edge Function: stripe-webhook
// Handles Stripe subscription events to update business tiers

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, stripe-signature",
};

// Tier mapping based on Stripe price IDs
const TIER_MAP: Record<string, { tier: string; radius: number }> = {
  "price_1TICCK2cfjexrkBqpbr03cXE": { tier: "premium", radius: 1000 },
  "price_1TICCL2cfjexrkBqIFUwYHbg": { tier: "gold", radius: 5000 },
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const body = await req.text();
    const signature = req.headers.get("stripe-signature");

    // TODO: Verify Stripe signature with webhook secret
    // For production, use Stripe SDK to verify:
    // const event = stripe.webhooks.constructEvent(body, signature, webhookSecret);

    const event = JSON.parse(body);

    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object;
        const customerId = session.customer;
        const subscriptionId = session.subscription;

        // Update business with Stripe IDs
        if (session.metadata?.business_id) {
          await supabase
            .from("businesses")
            .update({
              stripe_customer_id: customerId,
              stripe_subscription_id: subscriptionId,
            })
            .eq("id", session.metadata.business_id);
        }
        break;
      }

      case "customer.subscription.updated":
      case "customer.subscription.created": {
        const subscription = event.data.object;
        const priceId = subscription.items.data[0]?.price?.id;
        const customerId = subscription.customer;

        const tierConfig = TIER_MAP[priceId] ?? { tier: "free", radius: 100 };

        // Find business by Stripe customer ID
        const { data: business } = await supabase
          .from("businesses")
          .select("id")
          .eq("stripe_customer_id", customerId)
          .single();

        if (business) {
          await supabase
            .from("businesses")
            .update({
              subscription_tier: tierConfig.tier,
              geofence_radius_meters: tierConfig.radius,
              stripe_subscription_id: subscription.id,
              subscription_expires_at: new Date(
                subscription.current_period_end * 1000
              ).toISOString(),
            })
            .eq("id", business.id);
        }
        break;
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object;
        const customerId = subscription.customer;

        // Downgrade to free
        const { data: business } = await supabase
          .from("businesses")
          .select("id")
          .eq("stripe_customer_id", customerId)
          .single();

        if (business) {
          await supabase
            .from("businesses")
            .update({
              subscription_tier: "free",
              geofence_radius_meters: 100,
              stripe_subscription_id: null,
              subscription_expires_at: null,
            })
            .eq("id", business.id);
        }
        break;
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object;
        const customerId = invoice.customer;

        // TODO: Send email notification about failed payment
        console.log(`Payment failed for customer: ${customerId}`);
        break;
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Webhook error:", err);
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
