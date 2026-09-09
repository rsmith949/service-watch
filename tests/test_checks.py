"""Tests for individual checks."""

import socket
from datetime import datetime, timezone

import httpx
import pytest

from app.checks import check_dns, check_http, days_until


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


def test_check_dns_resolves(monkeypatch):
    def fake_getaddrinfo(host, port):
        return [
            (2, 1, 6, "", ("203.0.113.10", 0)),
            (2, 2, 17, "", ("203.0.113.10", 0)),
        ]

    monkeypatch.setattr(socket, "getaddrinfo", fake_getaddrinfo)
    result = check_dns("example.com")
    assert result.ok
    assert result.detail == "203.0.113.10"


def test_check_dns_does_not_resolve(monkeypatch):
    def fake_getaddrinfo(host, port):
        raise socket.gaierror("Name or service not known")

    monkeypatch.setattr(socket, "getaddrinfo", fake_getaddrinfo)
    result = check_dns("nope.invalid")
    assert not result.ok
    assert "did not resolve" in result.detail


def test_check_dns_unexpected_address(monkeypatch):
    def fake_getaddrinfo(host, port):
        return [(2, 1, 6, "", ("10.0.0.1", 0))]

    monkeypatch.setattr(socket, "getaddrinfo", fake_getaddrinfo)
    result = check_dns("example.com", expected="203.0.113.10")
    assert not result.ok
    assert "expected 203.0.113.10" in result.detail
