from __future__ import annotations

from typing import Any

from fastapi import FastAPI, HTTPException, Response, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from .config import WEB_ORIGIN
from .database import app_execute, app_fetch_all, app_fetch_one, app_insert_one, execute_readonly_query, jsonb
from .guardrails import SQLValidationError, limited_query
from .mock_agent import analyze_question

app = FastAPI(title="AI Analytics Chatbot API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[WEB_ORIGIN, "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    question: str = Field(min_length=1)
    sessionId: str | None = None


class ChatResponse(BaseModel):
    sessionId: str
    pendingQueryId: str
    title: str
    explanation: str
    sql: str
    chartSpec: dict[str, Any]


class QueryResult(BaseModel):
    pendingQueryId: str
    columns: list[str]
    rows: list[dict[str, Any]]
    rowCount: int


class SaveWidgetRequest(BaseModel):
    title: str
    question: str
    sql: str
    chartSpec: dict[str, Any]
    columns: list[str]
    rows: list[dict[str, Any]]


class DashboardWidget(BaseModel):
    id: str
    title: str
    question: str
    sql: str
    chartSpec: dict[str, Any]
    columns: list[str]
    rows: list[dict[str, Any]]
    createdAt: str


class DashboardResponse(BaseModel):
    name: str
    widgets: list[DashboardWidget]


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    session_id = ensure_session(request.sessionId)
    agent_result = analyze_question(request.question)

    pending = app_insert_one(
        """
        INSERT INTO app.pending_queries (session_id, question, explanation, sql, chart_spec)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING id
        """,
        (
            session_id,
            request.question,
            agent_result.explanation,
            agent_result.sql,
            jsonb(agent_result.chart_spec),
        ),
    )

    return ChatResponse(
        sessionId=session_id,
        pendingQueryId=pending["id"],
        title=agent_result.title,
        explanation=agent_result.explanation,
        sql=agent_result.sql,
        chartSpec=agent_result.chart_spec,
    )


@app.post("/queries/{pending_query_id}/approve", response_model=QueryResult)
def approve_query(pending_query_id: str) -> QueryResult:
    pending = app_fetch_one(
        """
        SELECT id, sql
        FROM app.pending_queries
        WHERE id = %s
        """,
        (pending_query_id,),
    )
    if pending is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pending query not found.")

    try:
        approved_sql = limited_query(pending["sql"])
    except SQLValidationError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    try:
        columns, rows = execute_readonly_query(approved_sql)
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Query failed: {exc}") from exc

    app_execute(
        """
        UPDATE app.pending_queries
        SET executed_at = now()
        WHERE id = %s
        """,
        (pending_query_id,),
    )

    return QueryResult(
        pendingQueryId=pending_query_id,
        columns=columns,
        rows=rows,
        rowCount=len(rows),
    )


@app.get("/dashboard", response_model=DashboardResponse)
def get_dashboard() -> DashboardResponse:
    rows = app_fetch_all(
        """
        SELECT
          id,
          title,
          question,
          sql,
          chart_spec,
          columns,
          rows,
          created_at
        FROM app.dashboard_widgets
        WHERE dashboard_name = 'My Dashboard'
        ORDER BY created_at DESC
        """
    )

    widgets = [
        DashboardWidget(
            id=row["id"],
            title=row["title"],
            question=row["question"],
            sql=row["sql"],
            chartSpec=row["chart_spec"],
            columns=row["columns"],
            rows=row["rows"],
            createdAt=row["created_at"],
        )
        for row in rows
    ]
    return DashboardResponse(name="My Dashboard", widgets=widgets)


@app.post("/dashboard/widgets", response_model=DashboardWidget, status_code=status.HTTP_201_CREATED)
def save_dashboard_widget(request: SaveWidgetRequest) -> DashboardWidget:
    row = app_insert_one(
        """
        INSERT INTO app.dashboard_widgets (
          dashboard_name,
          title,
          question,
          sql,
          chart_spec,
          columns,
          rows
        )
        VALUES ('My Dashboard', %s, %s, %s, %s, %s, %s)
        RETURNING id, title, question, sql, chart_spec, columns, rows, created_at
        """,
        (
            request.title,
            request.question,
            request.sql,
            jsonb(request.chartSpec),
            jsonb(request.columns),
            jsonb(request.rows),
        ),
    )
    return DashboardWidget(
        id=row["id"],
        title=row["title"],
        question=row["question"],
        sql=row["sql"],
        chartSpec=row["chart_spec"],
        columns=row["columns"],
        rows=row["rows"],
        createdAt=row["created_at"],
    )


@app.delete("/dashboard/widgets/{widget_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_dashboard_widget(widget_id: str) -> Response:
    app_execute(
        """
        DELETE FROM app.dashboard_widgets
        WHERE id = %s AND dashboard_name = 'My Dashboard'
        """,
        (widget_id,),
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)


def ensure_session(session_id: str | None) -> str:
    if session_id:
        existing = app_fetch_one("SELECT id FROM app.chat_sessions WHERE id = %s", (session_id,))
        if existing:
            return existing["id"]

    session = app_insert_one("INSERT INTO app.chat_sessions DEFAULT VALUES RETURNING id")
    return session["id"]
