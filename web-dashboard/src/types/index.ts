export interface Business {
  id: string;
  owner_id: string;
  name: string;
  description?: string;
  category: string;
  logo_url?: string;
  cover_image_url?: string;
  phone?: string;
  email?: string;
  address_line1: string;
  city: string;
  country: string;
  operating_hours: Record<string, { open: string; close: string }>;
  subscription_tier: "free" | "premium" | "gold";
  geofence_radius_meters: number;
  is_verified: boolean;
  is_active: boolean;
  created_at: string;
}

export interface Promotion {
  id: string;
  business_id: string;
  title: string;
  description: string;
  image_url?: string;
  discount_type: "percentage" | "fixed" | "bogo" | "free_item" | "custom";
  discount_value?: number;
  original_price?: number;
  status: "draft" | "active" | "paused" | "expired";
  starts_at: string;
  ends_at: string;
  active_days: string[];
  active_time_start?: string;
  active_time_end?: string;
  max_total_redemptions?: number;
  max_per_user: number;
  current_redemptions: number;
  created_at: string;
}

export interface Redemption {
  id: string;
  promotion_id: string;
  consumer_id: string;
  business_id: string;
  redemption_code: string;
  status: "claimed" | "redeemed" | "expired";
  claimed_at: string;
  redeemed_at?: string;
  expires_at: string;
}

export interface AnalyticsSummary {
  business_id: string;
  business_name: string;
  active_promotions: number;
  total_notifications_sent: number;
  notifications_opened: number;
  total_redemptions: number;
  confirmed_redemptions: number;
  open_rate: number;
  conversion_rate: number;
}
