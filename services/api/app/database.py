from __future__ import annotations

from collections.abc import Iterable, Sequence
from contextlib import contextmanager
from datetime import date, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

import psycopg
from psycopg.rows import dict_row
from psycopg.types.json import Jsonb

from .config import ANALYTICS_DATABASE_URL, APP_DATABASE_URL, STATEMENT_TIMEOUT_MS


def to_jsonable(value: Any) -> Any:
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, UUID):
        return str(value)
    if isinstance(value, list):
        return [to_jsonable(item) for item in value]
    if isinstance(value, dict):
        return {key: to_jsonable(item) for key, item in value.items()}
    return value


@contextmanager
def app_connection():
    with psycopg.connect(APP_DATABASE_URL, row_factory=dict_row) as conn:
        yield conn


def app_fetch_one(sql: str, params: Sequence[Any] | None = None) -> dict[str, Any] | None:
    with app_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            row = cur.fetchone()
            return to_jsonable(row) if row else None


def app_fetch_all(sql: str, params: Sequence[Any] | None = None) -> list[dict[str, Any]]:
    with app_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return to_jsonable(cur.fetchall())


def app_execute(sql: str, params: Sequence[Any] | None = None) -> None:
    with app_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())


def app_insert_one(sql: str, params: Sequence[Any] | None = None) -> dict[str, Any]:
    with app_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            row = cur.fetchone()
            if row is None:
                raise RuntimeError("Expected INSERT ... RETURNING to return a row")
            return to_jsonable(row)


def jsonb(value: Any) -> Jsonb:
    return Jsonb(value)


def execute_readonly_query(sql: str, params: Iterable[Any] | None = None) -> tuple[list[str], list[dict[str, Any]]]:
    with psycopg.connect(ANALYTICS_DATABASE_URL, row_factory=dict_row) as conn:
        with conn.transaction():
            with conn.cursor() as cur:
                cur.execute("SET TRANSACTION READ ONLY")
                cur.execute(f"SET LOCAL statement_timeout = '{int(STATEMENT_TIMEOUT_MS)}ms'")
                cur.execute(sql, tuple(params or ()))
                rows = cur.fetchall()
                columns = [column.name for column in cur.description or []]
                return columns, to_jsonable(rows)
