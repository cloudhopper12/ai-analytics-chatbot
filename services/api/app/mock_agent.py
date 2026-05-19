from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class AgentResult:
    title: str
    explanation: str
    sql: str
    chart_spec: dict[str, Any]


def analyze_question(question: str) -> AgentResult:
    normalized = question.lower()

    if "product" in normalized or "sku" in normalized:
        return top_products()
    if "region" in normalized or "state" in normalized:
        return revenue_by_region()
    if "campaign" in normalized or "conversion" in normalized or "convert" in normalized:
        return campaign_performance()
    if "inventory" in normalized or "stock" in normalized or "reorder" in normalized:
        return inventory_attention()
    if "profit" in normalized or "margin" in normalized:
        return gross_margin()
    return monthly_revenue()


def monthly_revenue() -> AgentResult:
    sql = """
SELECT
  to_char(date_trunc('month', o.order_date), 'YYYY-MM') AS month,
  ROUND(SUM(oi.quantity * oi.unit_price)::numeric, 2) AS revenue
FROM analytics.orders o
JOIN analytics.order_items oi ON oi.order_id = o.id
WHERE o.status IN ('paid', 'fulfilled', 'shipped')
GROUP BY 1
ORDER BY 1
""".strip()
    return AgentResult(
        title="Monthly revenue",
        explanation="This groups paid, fulfilled, and shipped orders by month and sums item revenue.",
        sql=sql,
        chart_spec={
            "kind": "bar",
            "title": "Monthly revenue",
            "xKey": "month",
            "yKey": "revenue",
            "valueLabel": "Revenue",
        },
    )


def top_products() -> AgentResult:
    sql = """
SELECT
  p.name AS product,
  c.name AS category,
  SUM(oi.quantity) AS units_sold,
  ROUND(SUM(oi.quantity * oi.unit_price)::numeric, 2) AS revenue
FROM analytics.order_items oi
JOIN analytics.orders o ON o.id = oi.order_id
JOIN analytics.products p ON p.id = oi.product_id
JOIN analytics.categories c ON c.id = p.category_id
WHERE o.status IN ('paid', 'fulfilled', 'shipped')
GROUP BY p.name, c.name
ORDER BY revenue DESC
LIMIT 8
""".strip()
    return AgentResult(
        title="Top products by revenue",
        explanation="This ranks products by revenue from completed orders.",
        sql=sql,
        chart_spec={
            "kind": "bar",
            "title": "Top products by revenue",
            "xKey": "product",
            "yKey": "revenue",
            "valueLabel": "Revenue",
        },
    )


def revenue_by_region() -> AgentResult:
    sql = """
SELECT
  c.region,
  COUNT(DISTINCT o.id) AS orders,
  ROUND(SUM(oi.quantity * oi.unit_price)::numeric, 2) AS revenue
FROM analytics.orders o
JOIN analytics.customers c ON c.id = o.customer_id
JOIN analytics.order_items oi ON oi.order_id = o.id
WHERE o.status IN ('paid', 'fulfilled', 'shipped')
GROUP BY c.region
ORDER BY revenue DESC
""".strip()
    return AgentResult(
        title="Revenue by region",
        explanation="This compares completed-order revenue across customer regions.",
        sql=sql,
        chart_spec={
            "kind": "bar",
            "title": "Revenue by region",
            "xKey": "region",
            "yKey": "revenue",
            "valueLabel": "Revenue",
        },
    )


def campaign_performance() -> AgentResult:
    sql = """
SELECT
  ca.name AS campaign,
  ca.channel,
  SUM(ws.visits) AS visits,
  SUM(ws.conversions) AS conversions,
  ROUND((SUM(ws.conversions)::numeric / NULLIF(SUM(ws.visits), 0)) * 100, 2) AS conversion_rate,
  ROUND(SUM(ws.revenue)::numeric, 2) AS attributed_revenue,
  ROUND(ca.spend::numeric, 2) AS spend
FROM analytics.campaigns ca
JOIN analytics.web_sessions ws ON ws.campaign_id = ca.id
GROUP BY ca.id, ca.name, ca.channel, ca.spend
ORDER BY attributed_revenue DESC
""".strip()
    return AgentResult(
        title="Campaign performance",
        explanation="This compares visits, conversions, conversion rate, spend, and attributed revenue by campaign.",
        sql=sql,
        chart_spec={
            "kind": "bar",
            "title": "Campaign attributed revenue",
            "xKey": "campaign",
            "yKey": "attributed_revenue",
            "valueLabel": "Attributed revenue",
        },
    )


def inventory_attention() -> AgentResult:
    sql = """
SELECT
  p.name AS product,
  i.stock_on_hand,
  i.reorder_point,
  (i.reorder_point - i.stock_on_hand) AS units_below_reorder
FROM analytics.inventory_snapshots i
JOIN analytics.products p ON p.id = i.product_id
WHERE i.snapshot_date = (
  SELECT MAX(snapshot_date) FROM analytics.inventory_snapshots
)
  AND i.stock_on_hand <= i.reorder_point
ORDER BY units_below_reorder DESC, p.name
""".strip()
    return AgentResult(
        title="Inventory needing attention",
        explanation="This finds products at or below their reorder point in the latest inventory snapshot.",
        sql=sql,
        chart_spec={
            "kind": "table",
            "title": "Inventory needing attention",
            "xKey": "product",
            "yKey": "units_below_reorder",
            "valueLabel": "Units below reorder",
        },
    )


def gross_margin() -> AgentResult:
    sql = """
SELECT
  to_char(date_trunc('month', o.order_date), 'YYYY-MM') AS month,
  ROUND(SUM(oi.quantity * (oi.unit_price - oi.unit_cost))::numeric, 2) AS gross_profit,
  ROUND((SUM(oi.quantity * (oi.unit_price - oi.unit_cost)) / NULLIF(SUM(oi.quantity * oi.unit_price), 0) * 100)::numeric, 2) AS gross_margin_pct
FROM analytics.orders o
JOIN analytics.order_items oi ON oi.order_id = o.id
WHERE o.status IN ('paid', 'fulfilled', 'shipped')
GROUP BY 1
ORDER BY 1
""".strip()
    return AgentResult(
        title="Monthly gross margin",
        explanation="This calculates gross profit and gross margin percentage by month.",
        sql=sql,
        chart_spec={
            "kind": "line",
            "title": "Monthly gross margin",
            "xKey": "month",
            "yKey": "gross_margin_pct",
            "valueLabel": "Gross margin %",
        },
    )
