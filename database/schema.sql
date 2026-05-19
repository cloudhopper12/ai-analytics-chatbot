CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE IF NOT EXISTS analytics.categories (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS analytics.products (
  id SERIAL PRIMARY KEY,
  category_id INTEGER NOT NULL REFERENCES analytics.categories(id),
  sku TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  unit_price NUMERIC(12, 2) NOT NULL,
  unit_cost NUMERIC(12, 2) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS analytics.customers (
  id SERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  region TEXT NOT NULL,
  acquisition_channel TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS analytics.orders (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES analytics.customers(id),
  order_date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('paid', 'fulfilled', 'shipped', 'refunded', 'cancelled')),
  shipping_region TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.order_items (
  id SERIAL PRIMARY KEY,
  order_id INTEGER NOT NULL REFERENCES analytics.orders(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES analytics.products(id),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(12, 2) NOT NULL,
  unit_cost NUMERIC(12, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.payments (
  id SERIAL PRIMARY KEY,
  order_id INTEGER NOT NULL REFERENCES analytics.orders(id) ON DELETE CASCADE,
  method TEXT NOT NULL,
  amount NUMERIC(12, 2) NOT NULL,
  paid_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('captured', 'refunded', 'failed'))
);

CREATE TABLE IF NOT EXISTS analytics.campaigns (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  channel TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  spend NUMERIC(12, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.web_sessions (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER REFERENCES analytics.customers(id),
  campaign_id INTEGER REFERENCES analytics.campaigns(id),
  session_date DATE NOT NULL,
  device_type TEXT NOT NULL,
  visits INTEGER NOT NULL CHECK (visits >= 0),
  conversions INTEGER NOT NULL CHECK (conversions >= 0),
  revenue NUMERIC(12, 2) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS analytics.inventory_snapshots (
  id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES analytics.products(id),
  snapshot_date DATE NOT NULL,
  stock_on_hand INTEGER NOT NULL CHECK (stock_on_hand >= 0),
  reorder_point INTEGER NOT NULL CHECK (reorder_point >= 0),
  UNIQUE (product_id, snapshot_date)
);

CREATE TABLE IF NOT EXISTS app.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app.pending_queries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES app.chat_sessions(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  explanation TEXT NOT NULL,
  sql TEXT NOT NULL,
  chart_spec JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  executed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS app.dashboard_widgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dashboard_name TEXT NOT NULL DEFAULT 'My Dashboard',
  title TEXT NOT NULL,
  question TEXT NOT NULL,
  sql TEXT NOT NULL,
  chart_spec JSONB NOT NULL,
  columns JSONB NOT NULL,
  rows JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_orders_order_date ON analytics.orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON analytics.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON analytics.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON analytics.order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_sessions_campaign_date ON analytics.web_sessions(campaign_id, session_date);
CREATE INDEX IF NOT EXISTS idx_dashboard_widgets_created ON app.dashboard_widgets(created_at DESC);

GRANT USAGE ON SCHEMA analytics TO analytics_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO analytics_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT ON TABLES TO analytics_readonly;

GRANT USAGE ON SCHEMA analytics, app TO analytics_app;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO analytics_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO analytics_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA analytics, app TO analytics_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO analytics_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT USAGE, SELECT ON SEQUENCES TO analytics_app;
