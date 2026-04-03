"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import type { Business } from "@/types";
import toast from "react-hot-toast";
import { Check, Zap, Crown, Star } from "lucide-react";

const plans = [
  {
    tier: "free",
    name: "Basic",
    price: "Free",
    period: "forever",
    radius: "50 - 100m",
    icon: Star,
    color: "gray",
    features: [
      "1 Active Promotion",
      "Basic Analytics",
      "QR Code Redemption",
      "50-100m Geofence Radius",
    ],
  },
  {
    tier: "premium",
    name: "Premium",
    price: "$49 - $79",
    period: "/month",
    radius: "500m - 1km",
    icon: Zap,
    color: "primary",
    popular: true,
    features: [
      "Up to 3 Active Promotions",
      "Advanced Analytics & ROI",
      "QR Code Redemption",
      "500m - 1km Geofence Radius",
      "Priority Support",
    ],
  },
  {
    tier: "gold",
    name: "Gold",
    price: "$129 - $199",
    period: "/month",
    radius: "2km - 5km",
    icon: Crown,
    color: "yellow",
    features: [
      "Unlimited Promotions",
      "Full Analytics Suite",
      "QR Code Redemption",
      "2km - 5km City-wide Radius",
      "Priority Listing in Feed",
      "Dedicated Account Manager",
    ],
  },
];

export default function SubscriptionPage() {
  const [business, setBusiness] = useState<Business | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return;

    const { data: biz } = await supabase
      .from("businesses")
      .select("*")
      .eq("owner_id", user.id)
      .single();

    if (biz) setBusiness(biz);
    setLoading(false);
  }

  function handleUpgrade(tier: string) {
    // TODO: Redirect to Stripe Checkout
    toast.success(`Stripe checkout for ${tier} plan coming soon!`);
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full"></div>
      </div>
    );
  }

  const currentTier = business?.subscription_tier ?? "free";

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold">Subscription</h1>
        <p className="text-gray-500">
          Choose the plan that fits your business needs
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {plans.map((plan) => {
          const isCurrent = plan.tier === currentTier;
          const colorMap: Record<string, string> = {
            gray: "gray-500",
            primary: "primary-500",
            yellow: "yellow-500",
          };

          return (
            <div
              key={plan.tier}
              className={`card relative overflow-hidden ${
                plan.popular ? "ring-2 ring-primary-500" : ""
              } ${isCurrent ? "ring-2 ring-green-500" : ""}`}
            >
              {plan.popular && (
                <div className="bg-primary-500 text-white text-xs font-bold py-1.5 text-center uppercase tracking-wider">
                  Most Popular
                </div>
              )}
              {isCurrent && (
                <div className="bg-green-500 text-white text-xs font-bold py-1.5 text-center uppercase tracking-wider">
                  Current Plan
                </div>
              )}

              <div className="p-8">
                <div className="flex items-center gap-3 mb-4">
                  <plan.icon
                    className={`w-8 h-8 text-${colorMap[plan.color]}`}
                  />
                  <h3 className="text-xl font-bold">{plan.name}</h3>
                </div>

                <div className="mb-2">
                  <span className="text-3xl font-bold">{plan.price}</span>
                  <span className="text-gray-500">{plan.period}</span>
                </div>
                <p className="text-sm text-primary-500 font-medium mb-6">
                  Geofence: {plan.radius}
                </p>

                <div className="border-t border-gray-100 pt-6 space-y-3 mb-8">
                  {plan.features.map((f) => (
                    <div key={f} className="flex items-center gap-3">
                      <Check className="w-5 h-5 text-green-500 flex-shrink-0" />
                      <span className="text-sm">{f}</span>
                    </div>
                  ))}
                </div>

                {!isCurrent && (
                  <button
                    onClick={() => handleUpgrade(plan.tier)}
                    className={`w-full py-3 rounded-xl font-semibold transition-colors ${
                      plan.popular
                        ? "bg-primary-500 text-white hover:bg-primary-600"
                        : "border border-gray-200 text-gray-700 hover:bg-gray-50"
                    }`}
                  >
                    {plan.tier === "free"
                      ? "Downgrade"
                      : `Upgrade to ${plan.name}`}
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
