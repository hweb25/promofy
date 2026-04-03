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

// Stripe Price IDs - set these after creating products in Stripe Dashboard
const PRICE_IDS: Record<string, string> = {
  premium: process.env.STRIPE_PREMIUM_PRICE_ID || "price_premium_placeholder",
  gold: process.env.STRIPE_GOLD_PRICE_ID || "price_gold_placeholder",
};

export async function POST(req: NextRequest) {
  try {
    const { tier, userId, businessId } = await req.json();

    if (!tier || !userId || !businessId) {
      return NextResponse.json(
        { error: "Missing required fields" },
        { status: 400 }
      );
    }

    if (!PRICE_IDS[tier]) {
      return NextResponse.json(
        { error: "Invalid subscription tier" },
        { status: 400 }
      );
    }

    // Get or create Stripe customer
    const { data: business } = await supabaseAdmin
      .from("businesses")
      .select("stripe_customer_id, name")
      .eq("id", businessId)
      .single();

    let customerId = business?.stripe_customer_id;

    if (!customerId) {
      const { data: profile } = await supabaseAdmin
        .from("profiles")
        .select("email, full_name")
        .eq("id", userId)
        .single();

      const customer = await stripe.customers.create({
        email: profile?.email,
        name: profile?.full_name || business?.name,
        metadata: {
          supabase_user_id: userId,
          business_id: businessId,
        },
      });

      customerId = customer.id;

      // Save Stripe customer ID
      await supabaseAdmin
        .from("businesses")
        .update({ stripe_customer_id: customerId })
        .eq("id", businessId);
    }

    // Create Stripe Checkout Session
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: [
        {
          price: PRICE_IDS[tier],
          quantity: 1,
        },
      ],
      success_url: `${req.nextUrl.origin}/dashboard/subscription?success=true&tier=${tier}`,
      cancel_url: `${req.nextUrl.origin}/dashboard/subscription?canceled=true`,
      metadata: {
        business_id: businessId,
        user_id: userId,
        tier: tier,
      },
      subscription_data: {
        metadata: {
          business_id: businessId,
          tier: tier,
        },
      },
    });

    return NextResponse.json({ url: session.url });
  } catch (error: any) {
    console.error("Stripe checkout error:", error);
    return NextResponse.json(
      { error: error.message || "Failed to create checkout session" },
      { status: 500 }
    );
  }
}
