"""Tests for individual checks."""

from datetime import datetime, timezone

import httpx
import pytest

from app.checks import check_http, days_until


class FakeResponse:
    def __init__(self, status_code: int):
        self.status_code = status_code


def test_http_ok(monkeypatch):
    monkeypatch.setattr(httpx, "get", lambda *a, **k: FakeResponse(200))
    result = check_http("https://example.invalid")
    assert result.ok is True
    assert result.detail == "status 200"
    assert result.latency_ms is not None


def test_http_wrong_status(monkeypatch):
    monkeypatch.setattr(httpx, "get", lambda *a, **k: FakeResponse(502))
    result = check_http("https://example.invalid")
    assert result.ok is False
    assert result.detail == "status 502"


def test_http_unreachable(monkeypatch):
    def boom(*a, **k):
        raise httpx.ConnectTimeout("no route to host")

    monkeypatch.setattr(httpx, "get", boom)
    result = check_http("https://example.invalid")
    assert result.ok is False
    assert result.detail.startswith("unreachable")
    assert result.latency_ms is None


def test_days_until_future():
    now = datetime(2026, 9, 1, tzinfo=timezone.utc)
    assert days_until("Dec  1 12:00:00 2026 GMT", now=now) == 91


def test_days_until_expired():
    now = datetime(2026, 9, 1, tzinfo=timezone.utc)
    assert days_until("Aug  1 12:00:00 2026 GMT", now=now) == -31


def test_days_until_rejects_garbage():
    with pytest.raises(ValueError):
        days_until("not a date")
