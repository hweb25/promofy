"use client";

import { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import type { AnalyticsSummary } from "@/types";
import {
  Bell,
  Eye,
  CheckCircle,
  TrendingUp,
  Megaphone,
  Target,
} from "lucide-react";

export default function AnalyticsPage() {
  const [analytics, setAnalytics] = useState<AnalyticsSummary | null>(null);
  const [events, setEvents] = useState<any[]>([]);
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
      .select("id")
      .eq("owner_id", user.id)
      .single();

    if (biz) {
      const { data: stats } = await supabase
        .from("business_analytics_summary")
        .select("*")
        .eq("business_id", biz.id)
        .single();
      if (stats) setAnalytics(stats);

      // Recent events
      const { data: recentEvents } = await supabase
        .from("analytics_events")
        .select("*")
        .eq("business_id", biz.id)
        .order("created_at", { ascending: false })
        .limit(20);
      if (recentEvents) setEvents(recentEvents);
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

  if (!analytics) {
    return (
      <div className="text-center py-20 text-gray-500">
        <Target className="w-16 h-16 mx-auto mb-4 text-gray-300" />
        <p className="text-lg font-medium">No analytics data yet</p>
        <p>Start creating promotions to see your analytics.</p>
      </div>
    );
  }

  const funnelData = [
    {
      label: "Notifications Sent",
      value: analytics.total_notifications_sent,
      icon: Bell,
      color: "bg-primary-500",
      bgLight: "bg-primary-50",
      textColor: "text-primary-600",
    },
    {
      label: "Notifications Opened",
      value: analytics.notifications_opened,
      icon: Eye,
      color: "bg-cyan-500",
      bgLight: "bg-cyan-50",
      textColor: "text-cyan-600",
    },
    {
      label: "Offers Claimed",
      value: analytics.total_redemptions,
      icon: Megaphone,
      color: "bg-orange-500",
      bgLight: "bg-orange-50",
      textColor: "text-orange-600",
    },
    {
      label: "Offers Redeemed",
      value: analytics.confirmed_redemptions,
      icon: CheckCircle,
      color: "bg-green-500",
      bgLight: "bg-green-50",
      textColor: "text-green-600",
    },
  ];

  const maxVal = Math.max(...funnelData.map((d) => d.value), 1);

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold">Analytics</h1>
        <p className="text-gray-500">
          Track your promotion performance and ROI
        </p>
      </div>

      {/* Rate Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div className="card p-8">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-cyan-50 rounded-xl flex items-center justify-center">
              <Eye className="w-6 h-6 text-cyan-500" />
            </div>
            <div>
              <div className="text-sm text-gray-500">Open Rate</div>
              <div className="text-3xl font-bold text-cyan-600">
                {analytics.open_rate}%
              </div>
            </div>
          </div>
          <div className="h-3 bg-gray-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-cyan-500 rounded-full transition-all duration-500"
              style={{ width: `${Math.min(analytics.open_rate, 100)}%` }}
            />
          </div>
        </div>

        <div className="card p-8">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-green-50 rounded-xl flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-green-500" />
            </div>
            <div>
              <div className="text-sm text-gray-500">Conversion Rate</div>
              <div className="text-3xl font-bold text-green-600">
                {analytics.conversion_rate}%
              </div>
            </div>
          </div>
          <div className="h-3 bg-gray-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-green-500 rounded-full transition-all duration-500"
              style={{
                width: `${Math.min(analytics.conversion_rate, 100)}%`,
              }}
            />
          </div>
        </div>
      </div>

      {/* Funnel */}
      <div className="card p-8 mb-8">
        <h2 className="text-lg font-bold mb-6">Conversion Funnel</h2>
        <div className="space-y-4">
          {funnelData.map((item) => (
            <div key={item.label} className="flex items-center gap-4">
              <div
                className={`w-10 h-10 ${item.bgLight} rounded-xl flex items-center justify-center`}
              >
                <item.icon className={`w-5 h-5 ${item.textColor}`} />
              </div>
              <div className="flex-1">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm text-gray-600">{item.label}</span>
                  <span className={`font-bold ${item.textColor}`}>
                    {item.value}
                  </span>
                </div>
                <div className="h-4 bg-gray-100 rounded-full overflow-hidden">
                  <div
                    className={`h-full ${item.color} rounded-full transition-all duration-700`}
                    style={{
                      width: `${(item.value / maxVal) * 100}%`,
                    }}
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Active Promotions */}
      <div className="card p-8 mb-8">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 bg-primary-50 rounded-2xl flex items-center justify-center">
            <Megaphone className="w-8 h-8 text-primary-500" />
          </div>
          <div>
            <div className="text-4xl font-bold text-primary-600">
              {analytics.active_promotions}
            </div>
            <div className="text-gray-500">Active Promotions</div>
          </div>
        </div>
      </div>

      {/* ROI Insight */}
      <div className="bg-green-50 border border-green-100 rounded-2xl p-6">
        <div className="flex items-start gap-4">
          <div className="w-10 h-10 bg-green-100 rounded-xl flex items-center justify-center flex-shrink-0">
            <TrendingUp className="w-5 h-5 text-green-600" />
          </div>
          <div>
            <h3 className="font-bold text-green-800">ROI Insight</h3>
            <p className="text-green-700 mt-1">
              <strong>{analytics.confirmed_redemptions}</strong> customers
              visited your business through Promofy promotions. Each redemption
              represents a direct foot-traffic conversion from a nearby
              notification.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
