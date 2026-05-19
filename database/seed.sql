TRUNCATE
  analytics.inventory_snapshots,
  analytics.web_sessions,
  analytics.payments,
  analytics.order_items,
  analytics.orders,
  analytics.customers,
  analytics.products,
  analytics.categories,
  analytics.campaigns
RESTART IDENTITY CASCADE;

INSERT INTO analytics.categories (name) VALUES
  ('Home Office'),
  ('Fitness'),
  ('Kitchen'),
  ('Travel'),
  ('Wellness');

INSERT INTO analytics.products (category_id, sku, name, unit_price, unit_cost) VALUES
  (1, 'DESK-001', 'Standing Desk Converter', 229.00, 118.00),
  (1, 'CHAIR-002', 'Ergo Mesh Chair', 349.00, 190.00),
  (1, 'LAMP-003', 'Task Lamp Pro', 79.00, 32.00),
  (2, 'MAT-004', 'Cork Yoga Mat', 88.00, 35.00),
  (2, 'BELL-005', 'Adjustable Dumbbell', 199.00, 101.00),
  (3, 'BLEND-006', 'Compact Blender', 129.00, 61.00),
  (3, 'KETTLE-007', 'Gooseneck Kettle', 94.00, 44.00),
  (4, 'PACK-008', 'Weekender Backpack', 159.00, 72.00),
  (4, 'CUBE-009', 'Packing Cube Set', 49.00, 18.00),
  (5, 'DIFF-010', 'Ceramic Diffuser', 68.00, 26.00);

INSERT INTO analytics.customers (first_name, last_name, email, region, acquisition_channel, created_at) VALUES
  ('Maya', 'Singh', 'maya@example.test', 'West', 'Organic Search', '2025-01-12'),
  ('Noah', 'Carter', 'noah@example.test', 'Northeast', 'Paid Search', '2025-02-03'),
  ('Ava', 'Martinez', 'ava@example.test', 'South', 'Email', '2025-02-11'),
  ('Ethan', 'Kim', 'ethan@example.test', 'West', 'Social', '2025-03-02'),
  ('Olivia', 'Brown', 'olivia@example.test', 'Midwest', 'Referral', '2025-03-18'),
  ('Liam', 'Garcia', 'liam@example.test', 'South', 'Organic Search', '2025-04-09'),
  ('Sophia', 'Lee', 'sophia@example.test', 'Northeast', 'Social', '2025-05-22'),
  ('Lucas', 'Wilson', 'lucas@example.test', 'West', 'Email', '2025-06-14'),
  ('Isabella', 'Davis', 'isabella@example.test', 'Midwest', 'Paid Search', '2025-07-01'),
  ('Mason', 'Clark', 'mason@example.test', 'South', 'Referral', '2025-08-19'),
  ('Amelia', 'Lopez', 'amelia@example.test', 'West', 'Organic Search', '2025-09-05'),
  ('James', 'Walker', 'james@example.test', 'Northeast', 'Email', '2025-10-10');

INSERT INTO analytics.campaigns (name, channel, start_date, end_date, spend) VALUES
  ('New Year Workspace', 'Paid Search', '2026-01-01', '2026-01-31', 4200.00),
  ('Spring Fitness Push', 'Social', '2026-03-01', '2026-03-31', 3600.00),
  ('Kitchen Upgrade', 'Email', '2026-04-01', '2026-04-30', 1800.00),
  ('Summer Travel', 'Social', '2026-05-01', '2026-06-15', 5100.00),
  ('Wellness Week', 'Organic Search', '2026-06-01', '2026-06-14', 900.00);

INSERT INTO analytics.orders (customer_id, order_date, status, shipping_region) VALUES
  (1, '2026-01-07', 'fulfilled', 'West'),
  (2, '2026-01-19', 'shipped', 'Northeast'),
  (3, '2026-02-04', 'fulfilled', 'South'),
  (4, '2026-02-16', 'paid', 'West'),
  (5, '2026-03-03', 'fulfilled', 'Midwest'),
  (6, '2026-03-21', 'shipped', 'South'),
  (7, '2026-04-08', 'fulfilled', 'Northeast'),
  (8, '2026-04-29', 'paid', 'West'),
  (9, '2026-05-12', 'fulfilled', 'Midwest'),
  (10, '2026-05-28', 'shipped', 'South'),
  (11, '2026-06-04', 'fulfilled', 'West'),
  (12, '2026-06-15', 'paid', 'Northeast'),
  (1, '2026-06-22', 'refunded', 'West'),
  (5, '2026-07-02', 'fulfilled', 'Midwest'),
  (8, '2026-07-09', 'paid', 'West');

INSERT INTO analytics.order_items (order_id, product_id, quantity, unit_price, unit_cost) VALUES
  (1, 1, 1, 229.00, 118.00),
  (1, 3, 2, 79.00, 32.00),
  (2, 2, 1, 349.00, 190.00),
  (3, 6, 1, 129.00, 61.00),
  (3, 7, 1, 94.00, 44.00),
  (4, 4, 2, 88.00, 35.00),
  (5, 5, 1, 199.00, 101.00),
  (5, 4, 1, 88.00, 35.00),
  (6, 5, 2, 199.00, 101.00),
  (7, 6, 2, 129.00, 61.00),
  (7, 10, 1, 68.00, 26.00),
  (8, 7, 1, 94.00, 44.00),
  (8, 3, 1, 79.00, 32.00),
  (9, 8, 2, 159.00, 72.00),
  (9, 9, 3, 49.00, 18.00),
  (10, 8, 1, 159.00, 72.00),
  (10, 9, 2, 49.00, 18.00),
  (11, 1, 1, 229.00, 118.00),
  (11, 2, 1, 349.00, 190.00),
  (12, 10, 3, 68.00, 26.00),
  (13, 4, 1, 88.00, 35.00),
  (14, 2, 1, 349.00, 190.00),
  (14, 3, 1, 79.00, 32.00),
  (15, 6, 1, 129.00, 61.00),
  (15, 7, 2, 94.00, 44.00);

INSERT INTO analytics.payments (order_id, method, amount, paid_at, status)
SELECT
  o.id,
  CASE WHEN o.id % 3 = 0 THEN 'paypal' WHEN o.id % 2 = 0 THEN 'apple_pay' ELSE 'card' END,
  ROUND(SUM(oi.quantity * oi.unit_price)::numeric, 2),
  o.order_date + TIME '10:00',
  CASE WHEN o.status = 'refunded' THEN 'refunded' ELSE 'captured' END
FROM analytics.orders o
JOIN analytics.order_items oi ON oi.order_id = o.id
GROUP BY o.id, o.order_date, o.status;

INSERT INTO analytics.web_sessions (customer_id, campaign_id, session_date, device_type, visits, conversions, revenue) VALUES
  (1, 1, '2026-01-08', 'desktop', 92, 7, 387.00),
  (2, 1, '2026-01-20', 'mobile', 75, 4, 349.00),
  (3, 1, '2026-02-02', 'mobile', 63, 3, 223.00),
  (4, 2, '2026-03-03', 'mobile', 118, 9, 176.00),
  (5, 2, '2026-03-21', 'desktop', 84, 5, 287.00),
  (6, 2, '2026-03-24', 'mobile', 109, 8, 398.00),
  (7, 3, '2026-04-08', 'desktop', 66, 5, 326.00),
  (8, 3, '2026-04-29', 'tablet', 42, 3, 173.00),
  (9, 4, '2026-05-12', 'mobile', 155, 12, 465.00),
  (10, 4, '2026-05-29', 'mobile', 143, 11, 257.00),
  (11, 5, '2026-06-04', 'desktop', 58, 4, 578.00),
  (12, 5, '2026-06-15', 'mobile', 49, 3, 204.00);

INSERT INTO analytics.inventory_snapshots (product_id, snapshot_date, stock_on_hand, reorder_point) VALUES
  (1, '2026-07-10', 18, 10),
  (2, '2026-07-10', 7, 12),
  (3, '2026-07-10', 42, 20),
  (4, '2026-07-10', 11, 15),
  (5, '2026-07-10', 6, 8),
  (6, '2026-07-10', 25, 15),
  (7, '2026-07-10', 13, 10),
  (8, '2026-07-10', 9, 14),
  (9, '2026-07-10', 55, 25),
  (10, '2026-07-10', 17, 10);
