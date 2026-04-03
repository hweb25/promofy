import { NextRequest, NextResponse } from "next/server";
import Stripe from "stripe";
import { createClient } from "@supabase/supabase-js";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2024-04-10",
});

const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const TIER_RADIUS: Record<string, number> = {
  premium: 1000,
  gold: 5000,
};

export async function POST(req: NextRequest) {
  const body = await req.text();
  const signature = req.headers.get("stripe-signature")!;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err: any) {
    console.error("Webhook signature verification failed:", err.message);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const businessId = session.metadata?.business_id;
        const tier = session.metadata?.tier;

        if (businessId && tier) {
          await supabaseAdmin
            .from("businesses")
            .update({
              subscription_tier: tier,
              geofence_radius: TIER_RADIUS[tier] || 100,
              stripe_customer_id: session.customer as string,
              stripe_subscription_id: session.subscription as string,
            })
            .eq("id", businessId);
        }
        break;
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription;
        const businessId = subscription.metadata?.business_id;
        const tier = subscription.metadata?.tier;

        if (businessId) {
          const isActive = ["active", "trialing"].includes(
            subscription.status
          );
          await supabaseAdmin
            .from("businesses")
            .update({
              subscription_tier: isActive ? (tier ?? "free") : "free",
              geofence_radius: isActive ? (TIER_RADIUS[tier!] || 100) : 100,
            })
            .eq("id", businessId);
        }
        break;
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        const businessId = subscription.metadata?.business_id;

        if (businessId) {
          await supabaseAdmin
            .from("businesses")
            .update({
              subscription_tier: "free",
              geofence_radius: 100,
              stripe_subscription_id: null,
            })
            .eq("id", businessId);
        }
        break;
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object as Stripe.Invoice;
        console.error(
          "Payment failed for customer:",
          invoice.customer,
          "Subscription:",
          invoice.subscription
        );
        break;
      }
    }
  } catch (error) {
    console.error("Webhook handler error:", error);
    return NextResponse.json(
      { error: "Webhook handler failed" },
      { status: 500 }
    );
  }

  return NextResponse.json({ received: true });
}
