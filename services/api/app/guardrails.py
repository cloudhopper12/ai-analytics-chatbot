from __future__ import annotations

import sqlglot
from sqlglot import exp

from .config import MAX_QUERY_ROWS


class SQLValidationError(ValueError):
    pass


DISALLOWED_EXPRESSIONS = (
    exp.Command,
    exp.Create,
    exp.Delete,
    exp.Drop,
    exp.Insert,
    exp.Merge,
    exp.Update,
)


def validate_readonly_sql(sql: str) -> str:
    stripped = sql.strip().rstrip(";").strip()
    if not stripped:
        raise SQLValidationError("SQL cannot be empty.")
    if ";" in stripped:
        raise SQLValidationError("Only a single SQL statement is allowed.")

    try:
        parsed = sqlglot.parse(stripped, read="postgres")
    except sqlglot.errors.ParseError as exc:
        raise SQLValidationError("SQL could not be parsed.") from exc

    if len(parsed) != 1:
        raise SQLValidationError("Only a single SQL statement is allowed.")

    statement = parsed[0]
    if not isinstance(statement, (exp.Select, exp.Union)):
        raise SQLValidationError("Only read-only SELECT queries are allowed.")

    for node in statement.walk():
        if isinstance(node, DISALLOWED_EXPRESSIONS):
            raise SQLValidationError("Only read-only SELECT queries are allowed.")

    return stripped


def limited_query(sql: str) -> str:
    validated = validate_readonly_sql(sql)
    return f"SELECT * FROM ({validated}) AS approved_query LIMIT {MAX_QUERY_ROWS}"
