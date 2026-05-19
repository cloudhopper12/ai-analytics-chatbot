import pytest

from app.guardrails import SQLValidationError, limited_query, validate_readonly_sql


def test_select_is_allowed():
    assert validate_readonly_sql("select * from analytics.orders") == "select * from analytics.orders"


def test_multi_statement_is_rejected():
    with pytest.raises(SQLValidationError):
        validate_readonly_sql("select 1; drop table analytics.orders")


def test_writes_are_rejected():
    with pytest.raises(SQLValidationError):
        validate_readonly_sql("delete from analytics.orders")


def test_query_is_wrapped_with_outer_limit():
    wrapped = limited_query("select * from analytics.orders")
    assert wrapped.startswith("SELECT * FROM (select * from analytics.orders)")
    assert "LIMIT" in wrapped
