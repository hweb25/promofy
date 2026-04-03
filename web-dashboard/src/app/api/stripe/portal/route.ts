import { NextRequest, NextResponse } from "next/server";
import Stripe from "stripe";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2024-04-10",
});

export async function POST(req: NextRequest) {
  try {
    const { customerId } = await req.json();

    if (!customerId) {
      return NextResponse.json(
        { error: "Missing customer ID" },
        { status: 400 }
      );
    }

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: `${req.nextUrl.origin}/dashboard/subscription`,
    });

    return NextResponse.json({ url: session.url });
  } catch (error: any) {
    console.error("Portal error:", error);
    return NextResponse.json(
      { error: error.message || "Failed to create portal session" },
      { status: 500 }
    );
  }
}
