"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import type { Business, AnalyticsSummary, Promotion } from "@/types";
import {
  Bell,
  Eye,
  CheckCircle,
  TrendingUp,
  Plus,
  ArrowRight,
  Megaphone,
} from "lucide-react";

export default function DashboardPage() {
  const [business, setBusiness] = useState<Business | null>(null);
  const [analytics, setAnalytics] = useState<AnalyticsSummary | null>(null);
  const [promotions, setPromotions] = useState<Promotion[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return;

    // Load business
    const { data: biz } = await supabase
      .from("businesses")
      .select("*")
      .eq("owner_id", user.id)
      .single();

    if (biz) {
      setBusiness(biz);

      // Load analytics
      const { data: stats } = await supabase
        .from("business_analytics_summary")
        .select("*")
        .eq("business_id", biz.id)
        .single();
      if (stats) setAnalytics(stats);

      // Load promotions
      const { data: promos } = await supabase
        .from("promotions")
        .select("*")
        .eq("business_id", biz.id)
        .order("created_at", { ascending: false })
        .limit(5);
      if (promos) setPromotions(promos);
    }

    setLoading(false);
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full"></div>
      </div>
    );
  }

  if (!business) {
    return (
      <div className="flex flex-col items-center justify-center h-[60vh] text-center">
        <div className="w-24 h-24 bg-primary-50 rounded-full flex items-center justify-center mb-6">
          <Megaphone className="w-12 h-12 text-primary-500" />
        </div>
        <h2 className="text-2xl font-bold mb-3">Set Up Your Business</h2>
        <p className="text-gray-500 mb-8 max-w-md">
          Create your business profile to start publishing promotions and
          attracting customers.
        </p>
        <Link href="/dashboard/settings" className="btn-primary">
          Get Started
        </Link>
      </div>
    );
  }

  const stats = [
    {
      label: "Notifications Sent",
      value: analytics?.total_notifications_sent ?? 0,
      icon: Bell,
      color: "text-primary-500",
      bg: "bg-primary-50",
    },
    {
      label: "Opened",
      value: analytics?.notifications_opened ?? 0,
      icon: Eye,
      color: "text-cyan-500",
      bg: "bg-cyan-50",
    },
    {
      label: "Redeemed",
      value: analytics?.confirmed_redemptions ?? 0,
      icon: CheckCircle,
      color: "text-green-500",
      bg: "bg-green-50",
    },
    {
      label: "Conversion Rate",
      value: `${analytics?.conversion_rate ?? 0}%`,
      icon: TrendingUp,
      color: "text-orange-500",
      bg: "bg-orange-50",
    },
  ];

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">{business.name}</h1>
          <p className="text-gray-500">
            Welcome back! Here&apos;s your business overview.
          </p>
        </div>
        <Link
          href="/dashboard/promotions"
          className="btn-primary flex items-center gap-2"
        >
          <Plus className="w-5 h-5" />
          New Promotion
        </Link>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {stats.map((stat) => (
          <div key={stat.label} className="stat-card">
            <div className={`w-10 h-10 ${stat.bg} rounded-xl flex items-center justify-center`}>
              <stat.icon className={`w-5 h-5 ${stat.color}`} />
            </div>
            <div className="text-2xl font-bold mt-2">{stat.value}</div>
            <div className="text-sm text-gray-500">{stat.label}</div>
          </div>
        ))}
      </div>

      {/* Subscription Banner */}
      <div className="bg-gradient-to-r from-primary-500 to-primary-700 rounded-2xl p-6 text-white mb-8 flex items-center justify-between">
        <div>
          <div className="text-sm font-medium text-white/80 mb-1">
            Current Plan
          </div>
          <div className="text-2xl font-bold capitalize">
            {business.subscription_tier} Plan
          </div>
          <div className="text-white/80 mt-1">
            Geofence radius: {business.geofence_radius_meters}m
          </div>
        </div>
        <Link
          href="/dashboard/subscription"
          className="bg-white text-primary-600 px-5 py-2.5 rounded-xl font-semibold hover:bg-white/90 transition-colors"
        >
          Upgrade Plan
        </Link>
      </div>

      {/* Recent Promotions */}
      <div className="card">
        <div className="flex items-center justify-between p-6 border-b border-gray-100">
          <h2 className="text-lg font-bold">Recent Promotions</h2>
          <Link
            href="/dashboard/promotions"
            className="text-primary-500 text-sm font-medium flex items-center gap-1 hover:underline"
          >
            View All <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        {promotions.length === 0 ? (
          <div className="p-12 text-center text-gray-500">
            <Megaphone className="w-12 h-12 mx-auto mb-4 text-gray-300" />
            <p className="font-medium">No promotions yet</p>
            <p className="text-sm mt-1">
              Create your first promotion to start attracting customers.
            </p>
          </div>
        ) : (
          <div className="divide-y divide-gray-50">
            {promotions.map((promo) => (
              <div
                key={promo.id}
                className="flex items-center gap-4 px-6 py-4 hover:bg-gray-50 transition-colors"
              >
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                    promo.status === "active"
                      ? "bg-green-50 text-green-500"
                      : promo.status === "paused"
                      ? "bg-yellow-50 text-yellow-500"
                      : "bg-gray-50 text-gray-400"
                  }`}
                >
                  <Megaphone className="w-5 h-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-medium truncate">{promo.title}</div>
                  <div className="text-sm text-gray-500">
                    {promo.current_redemptions} redeemed
                  </div>
                </div>
                <span
                  className={`text-xs font-semibold px-3 py-1 rounded-full ${
                    promo.status === "active"
                      ? "bg-green-50 text-green-600"
                      : promo.status === "paused"
                      ? "bg-yellow-50 text-yellow-600"
                      : "bg-gray-50 text-gray-500"
                  }`}
                >
                  {promo.status.toUpperCase()}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
