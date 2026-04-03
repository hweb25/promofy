-- Add Stripe integration columns to businesses table
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;
ALTER TABLE businesses ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT;

-- Create index for Stripe lookups
CREATE INDEX IF NOT EXISTS idx_businesses_stripe_customer ON businesses(stripe_customer_id) WHERE stripe_customer_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_businesses_stripe_subscription ON businesses(stripe_subscription_id) WHERE stripe_subscription_id IS NOT NULL;
