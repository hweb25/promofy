-- ============================================
-- PROMOFY DATABASE SCHEMA
-- Supabase PostgreSQL + PostGIS
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- ============================================
-- ENUMS
-- ============================================
CREATE TYPE subscription_tier AS ENUM ('free', 'premium', 'gold');
CREATE TYPE promotion_status AS ENUM ('draft', 'active', 'paused', 'expired');
CREATE TYPE redemption_status AS ENUM ('claimed', 'redeemed', 'expired');
CREATE TYPE user_role AS ENUM ('consumer', 'business_owner', 'admin');
CREATE TYPE business_category AS ENUM ('restaurant', 'bar', 'cafe', 'food_truck', 'bakery', 'other');
CREATE TYPE day_of_week AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');

-- ============================================
-- PROFILES (extends Supabase auth.users)
-- ============================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'consumer',
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    preferred_categories business_category[] DEFAULT '{}',
    max_daily_notifications INTEGER DEFAULT 2,
    push_token TEXT,
    device_platform TEXT CHECK (device_platform IN ('ios', 'android', 'web')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- BUSINESSES
-- ============================================
CREATE TABLE businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category business_category NOT NULL DEFAULT 'restaurant',
    logo_url TEXT,
    cover_image_url TEXT,
    phone TEXT,
    email TEXT,
    website TEXT,

    -- Address
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state TEXT,
    postal_code TEXT,
    country TEXT NOT NULL DEFAULT 'CO',

    -- PostGIS location (longitude, latitude)
    location GEOGRAPHY(POINT, 4326) NOT NULL,

    -- Operating hours (JSONB for flexibility)
    -- Format: {"monday": {"open": "09:00", "close": "22:00"}, ...}
    operating_hours JSONB DEFAULT '{}',

    -- Subscription
    subscription_tier subscription_tier DEFAULT 'free',
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    subscription_expires_at TIMESTAMPTZ,

    -- Geofencing
    geofence_radius_meters INTEGER DEFAULT 100,

    -- Verification
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMPTZ,

    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spatial index for fast geofencing queries
CREATE INDEX idx_businesses_location ON businesses USING GIST(location);
CREATE INDEX idx_businesses_owner ON businesses(owner_id);
CREATE INDEX idx_businesses_category ON businesses(category);
CREATE INDEX idx_businesses_active ON businesses(is_active) WHERE is_active = true;

-- ============================================
-- PROMOTIONS
-- ============================================
CREATE TABLE promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,

    title TEXT NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT,

    -- Promotion details
    discount_type TEXT CHECK (discount_type IN ('percentage', 'fixed', 'bogo', 'free_item', 'custom')),
    discount_value NUMERIC(10, 2),
    original_price NUMERIC(10, 2),

    -- Schedule
    status promotion_status DEFAULT 'draft',
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    active_days day_of_week[] DEFAULT '{monday,tuesday,wednesday,thursday,friday,saturday,sunday}',
    active_time_start TIME, -- e.g., 17:00 for happy hour
    active_time_end TIME,   -- e.g., 19:00

    -- Limits
    max_total_redemptions INTEGER, -- NULL = unlimited
    max_per_user INTEGER DEFAULT 1,
    current_redemptions INTEGER DEFAULT 0,

    -- Targeting
    categories business_category[] DEFAULT '{}',

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_promotions_business ON promotions(business_id);
CREATE INDEX idx_promotions_status ON promotions(status);
CREATE INDEX idx_promotions_dates ON promotions(starts_at, ends_at);

-- ============================================
-- REDEMPTIONS (QR Code based)
-- ============================================
CREATE TABLE redemptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    consumer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,

    -- QR/Code
    redemption_code TEXT NOT NULL UNIQUE,
    qr_data TEXT NOT NULL, -- JSON encoded QR data

    status redemption_status DEFAULT 'claimed',
    claimed_at TIMESTAMPTZ DEFAULT NOW(),
    redeemed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL, -- Code expiry (e.g., 30 min after claim)

    -- Validation
    validated_by UUID REFERENCES profiles(id), -- Staff who scanned

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_redemptions_consumer ON redemptions(consumer_id);
CREATE INDEX idx_redemptions_promotion ON redemptions(promotion_id);
CREATE INDEX idx_redemptions_code ON redemptions(redemption_code);
CREATE INDEX idx_redemptions_status ON redemptions(status);

-- ============================================
-- NOTIFICATION LOG
-- ============================================
CREATE TABLE notification_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    consumer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    promotion_id UUID NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,

    title TEXT NOT NULL,
    body TEXT NOT NULL,

    -- Tracking
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    opened_at TIMESTAMPTZ,

    -- Geofence trigger data
    trigger_latitude DOUBLE PRECISION,
    trigger_longitude DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION
);

CREATE INDEX idx_notifications_consumer ON notification_log(consumer_id);
CREATE INDEX idx_notifications_business ON notification_log(business_id);
CREATE INDEX idx_notifications_sent ON notification_log(sent_at);

-- ============================================
-- COOLDOWN TRACKING (prevents spam)
-- ============================================
CREATE TABLE notification_cooldowns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    consumer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    last_notified_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(consumer_id, business_id)
);

CREATE INDEX idx_cooldowns_consumer ON notification_cooldowns(consumer_id);

-- ============================================
-- FAVORITES
-- ============================================
CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    consumer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(consumer_id, business_id)
);

-- ============================================
-- ANALYTICS EVENTS
-- ============================================
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL, -- 'notification_sent', 'notification_opened', 'promotion_viewed', 'offer_claimed', 'offer_redeemed'
    promotion_id UUID REFERENCES promotions(id),
    consumer_id UUID REFERENCES profiles(id),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_analytics_business ON analytics_events(business_id);
CREATE INDEX idx_analytics_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_date ON analytics_events(created_at);

-- ============================================
-- VIEWS
-- ============================================

-- Active promotions with business info (for consumer feed)
CREATE OR REPLACE VIEW active_promotions_view AS
SELECT
    p.*,
    b.name AS business_name,
    b.logo_url AS business_logo,
    b.category AS business_category,
    b.location AS business_location,
    b.geofence_radius_meters,
    b.operating_hours,
    ST_Y(b.location::geometry) AS latitude,
    ST_X(b.location::geometry) AS longitude
FROM promotions p
JOIN businesses b ON p.business_id = b.id
WHERE p.status = 'active'
  AND b.is_active = true
  AND p.starts_at <= NOW()
  AND p.ends_at >= NOW()
  AND (p.max_total_redemptions IS NULL OR p.current_redemptions < p.max_total_redemptions);

-- Business analytics summary
CREATE OR REPLACE VIEW business_analytics_summary AS
SELECT
    b.id AS business_id,
    b.name AS business_name,
    COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'active') AS active_promotions,
    COUNT(DISTINCT nl.id) AS total_notifications_sent,
    COUNT(DISTINCT nl.id) FILTER (WHERE nl.opened_at IS NOT NULL) AS notifications_opened,
    COUNT(DISTINCT r.id) AS total_redemptions,
    COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'redeemed') AS confirmed_redemptions,
    CASE
        WHEN COUNT(DISTINCT nl.id) > 0
        THEN ROUND(COUNT(DISTINCT nl.id) FILTER (WHERE nl.opened_at IS NOT NULL)::NUMERIC / COUNT(DISTINCT nl.id) * 100, 1)
        ELSE 0
    END AS open_rate,
    CASE
        WHEN COUNT(DISTINCT nl.id) > 0
        THEN ROUND(COUNT(DISTINCT r.id) FILTER (WHERE r.status = 'redeemed')::NUMERIC / COUNT(DISTINCT nl.id) * 100, 1)
        ELSE 0
    END AS conversion_rate
FROM businesses b
LEFT JOIN promotions p ON p.business_id = b.id
LEFT JOIN notification_log nl ON nl.business_id = b.id
LEFT JOIN redemptions r ON r.business_id = b.id
GROUP BY b.id, b.name;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function: Find nearby active promotions for a consumer
CREATE OR REPLACE FUNCTION get_nearby_promotions(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 5000
)
RETURNS TABLE (
    promotion_id UUID,
    title TEXT,
    description TEXT,
    image_url TEXT,
    discount_type TEXT,
    discount_value NUMERIC,
    business_name TEXT,
    business_logo TEXT,
    business_category business_category,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION,
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    geofence_radius INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id AS promotion_id,
        p.title,
        p.description,
        p.image_url,
        p.discount_type,
        p.discount_value,
        b.name AS business_name,
        b.logo_url AS business_logo,
        b.category AS business_category,
        ST_Y(b.location::geometry) AS latitude,
        ST_X(b.location::geometry) AS longitude,
        ST_Distance(
            b.location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        ) AS distance_meters,
        p.starts_at,
        p.ends_at,
        b.geofence_radius_meters AS geofence_radius
    FROM promotions p
    JOIN businesses b ON p.business_id = b.id
    WHERE p.status = 'active'
      AND b.is_active = true
      AND p.starts_at <= NOW()
      AND p.ends_at >= NOW()
      AND (p.max_total_redemptions IS NULL OR p.current_redemptions < p.max_total_redemptions)
      AND ST_DWithin(
          b.location,
          ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
          radius_meters
      )
    ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Check if notification can be sent (cooldown + frequency cap)
CREATE OR REPLACE FUNCTION can_send_notification(
    p_consumer_id UUID,
    p_business_id UUID,
    p_cooldown_hours INTEGER DEFAULT 24,
    p_daily_limit INTEGER DEFAULT 2
)
RETURNS BOOLEAN AS $$
DECLARE
    last_notified TIMESTAMPTZ;
    today_count INTEGER;
BEGIN
    -- Check cooldown for this specific business
    SELECT last_notified_at INTO last_notified
    FROM notification_cooldowns
    WHERE consumer_id = p_consumer_id AND business_id = p_business_id;

    IF last_notified IS NOT NULL AND last_notified > NOW() - (p_cooldown_hours || ' hours')::INTERVAL THEN
        RETURN FALSE;
    END IF;

    -- Check daily notification limit
    SELECT COUNT(*) INTO today_count
    FROM notification_log
    WHERE consumer_id = p_consumer_id
      AND sent_at >= DATE_TRUNC('day', NOW());

    IF today_count >= p_daily_limit THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Claim a promotion (generate QR code)
CREATE OR REPLACE FUNCTION claim_promotion(
    p_consumer_id UUID,
    p_promotion_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_business_id UUID;
    v_redemption_code TEXT;
    v_redemption_id UUID;
    v_max_per_user INTEGER;
    v_user_claims INTEGER;
    v_max_total INTEGER;
    v_current INTEGER;
BEGIN
    -- Get promotion details
    SELECT business_id, max_per_user, max_total_redemptions, current_redemptions
    INTO v_business_id, v_max_per_user, v_max_total, v_current
    FROM promotions
    WHERE id = p_promotion_id AND status = 'active';

    IF v_business_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Promotion not found or inactive');
    END IF;

    -- Check max total redemptions
    IF v_max_total IS NOT NULL AND v_current >= v_max_total THEN
        RETURN json_build_object('success', false, 'error', 'Promotion fully redeemed');
    END IF;

    -- Check per-user limit
    SELECT COUNT(*) INTO v_user_claims
    FROM redemptions
    WHERE promotion_id = p_promotion_id
      AND consumer_id = p_consumer_id
      AND status IN ('claimed', 'redeemed');

    IF v_user_claims >= v_max_per_user THEN
        RETURN json_build_object('success', false, 'error', 'You have already claimed this offer');
    END IF;

    -- Generate unique code
    v_redemption_code := UPPER(SUBSTR(MD5(RANDOM()::TEXT || NOW()::TEXT), 1, 8));
    v_redemption_id := uuid_generate_v4();

    -- Create redemption
    INSERT INTO redemptions (id, promotion_id, consumer_id, business_id, redemption_code, qr_data, expires_at)
    VALUES (
        v_redemption_id,
        p_promotion_id,
        p_consumer_id,
        v_business_id,
        v_redemption_code,
        json_build_object(
            'redemption_id', v_redemption_id,
            'code', v_redemption_code,
            'promotion_id', p_promotion_id,
            'consumer_id', p_consumer_id,
            'business_id', v_business_id,
            'claimed_at', NOW()
        )::TEXT,
        NOW() + INTERVAL '30 minutes'
    );

    -- Increment redemption counter
    UPDATE promotions SET current_redemptions = current_redemptions + 1 WHERE id = p_promotion_id;

    RETURN json_build_object(
        'success', true,
        'redemption_id', v_redemption_id,
        'code', v_redemption_code,
        'expires_at', NOW() + INTERVAL '30 minutes'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Validate a redemption (business scans QR)
CREATE OR REPLACE FUNCTION validate_redemption(
    p_redemption_code TEXT,
    p_business_id UUID,
    p_validated_by UUID
)
RETURNS JSON AS $$
DECLARE
    v_redemption RECORD;
BEGIN
    SELECT * INTO v_redemption
    FROM redemptions
    WHERE redemption_code = p_redemption_code AND business_id = p_business_id;

    IF v_redemption IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Invalid code or wrong business');
    END IF;

    IF v_redemption.status = 'redeemed' THEN
        RETURN json_build_object('success', false, 'error', 'Code already redeemed');
    END IF;

    IF v_redemption.status = 'expired' OR v_redemption.expires_at < NOW() THEN
        UPDATE redemptions SET status = 'expired' WHERE id = v_redemption.id;
        RETURN json_build_object('success', false, 'error', 'Code has expired');
    END IF;

    -- Mark as redeemed
    UPDATE redemptions
    SET status = 'redeemed', redeemed_at = NOW(), validated_by = p_validated_by
    WHERE id = v_redemption.id;

    -- Log analytics event
    INSERT INTO analytics_events (business_id, event_type, promotion_id, consumer_id)
    VALUES (p_business_id, 'offer_redeemed', v_redemption.promotion_id, v_redemption.consumer_id);

    RETURN json_build_object(
        'success', true,
        'redemption_id', v_redemption.id,
        'promotion_id', v_redemption.promotion_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_cooldowns ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Public profiles readable" ON profiles FOR SELECT USING (true);
CREATE POLICY "Profile created on signup" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Businesses policies
CREATE POLICY "Anyone can view active businesses" ON businesses FOR SELECT USING (is_active = true);
CREATE POLICY "Owners can manage their business" ON businesses FOR ALL USING (auth.uid() = owner_id);
CREATE POLICY "Admins can manage all businesses" ON businesses FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Promotions policies
CREATE POLICY "Anyone can view active promotions" ON promotions FOR SELECT USING (status = 'active');
CREATE POLICY "Business owners manage own promotions" ON promotions FOR ALL USING (
    EXISTS (SELECT 1 FROM businesses WHERE id = promotions.business_id AND owner_id = auth.uid())
);

-- Redemptions policies
CREATE POLICY "Consumers see own redemptions" ON redemptions FOR SELECT USING (auth.uid() = consumer_id);
CREATE POLICY "Business owners see their redemptions" ON redemptions FOR SELECT USING (
    EXISTS (SELECT 1 FROM businesses WHERE id = redemptions.business_id AND owner_id = auth.uid())
);
CREATE POLICY "Consumers can claim" ON redemptions FOR INSERT WITH CHECK (auth.uid() = consumer_id);

-- Notification log policies
CREATE POLICY "Consumers see own notifications" ON notification_log FOR SELECT USING (auth.uid() = consumer_id);
CREATE POLICY "Business owners see their notifications" ON notification_log FOR SELECT USING (
    EXISTS (SELECT 1 FROM businesses WHERE id = notification_log.business_id AND owner_id = auth.uid())
);

-- Favorites policies
CREATE POLICY "Users manage own favorites" ON favorites FOR ALL USING (auth.uid() = consumer_id);

-- Analytics policies
CREATE POLICY "Business owners see own analytics" ON analytics_events FOR SELECT USING (
    EXISTS (SELECT 1 FROM businesses WHERE id = analytics_events.business_id AND owner_id = auth.uid())
);

-- ============================================
-- TRIGGERS
-- ============================================

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, full_name, avatar_url, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', ''),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'consumer')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_businesses_updated_at BEFORE UPDATE ON businesses FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_promotions_updated_at BEFORE UPDATE ON promotions FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-expire promotions
CREATE OR REPLACE FUNCTION expire_old_promotions()
RETURNS void AS $$
BEGIN
    UPDATE promotions SET status = 'expired' WHERE ends_at < NOW() AND status = 'active';
    UPDATE redemptions SET status = 'expired' WHERE expires_at < NOW() AND status = 'claimed';
END;
$$ LANGUAGE plpgsql;
