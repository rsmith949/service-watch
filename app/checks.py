"""Individual health checks for monitored services."""

import socket
import ssl
import time
from dataclasses import dataclass
from datetime import datetime, timezone

import httpx

CERT_TIME_FORMAT = "%b %d %H:%M:%S %Y %Z"


@dataclass
class CheckResult:
    name: str
    ok: bool
    detail: str
    latency_ms: float | None = None


def days_until(not_after: str, now: datetime | None = None) -> int:
    """Whole days between now and a certificate's notAfter string."""
    expires = datetime.strptime(not_after, CERT_TIME_FORMAT).replace(tzinfo=timezone.utc)
    if now is None:
        now = datetime.now(timezone.utc)
    return (expires - now).days


def check_http(url: str, expected_status: int = 200, timeout: float = 10.0) -> CheckResult:
    """Fetch a URL and report whether it answered as expected."""
    started = time.perf_counter()
    try:
        response = httpx.get(url, timeout=timeout, follow_redirects=True)
    except httpx.RequestError as exc:
        return CheckResult(name="http", ok=False, detail=f"unreachable: {type(exc).__name__}")
    latency_ms = round((time.perf_counter() - started) * 1000, 1)
    return CheckResult(
        name="http",
        ok=response.status_code == expected_status,
        detail=f"status {response.status_code}",
        latency_ms=latency_ms,
    )


def check_tls(hostname: str, port: int = 443, warn_days: int = 14, timeout: float = 10.0) -> CheckResult:
    """Report how many days remain before the TLS certificate expires."""
    context = ssl.create_default_context()
    try:
        with socket.create_connection((hostname, port), timeout=timeout) as raw:
            with context.wrap_socket(raw, server_hostname=hostname) as tls:
                cert = tls.getpeercert()
    except OSError as exc:
        return CheckResult(name="tls", ok=False, detail=f"handshake failed: {type(exc).__name__}")
    days_left = days_until(cert["notAfter"])
    return CheckResult(
        name="tls",
        ok=days_left > warn_days,
        detail=f"{days_left} days until expiry",
    )
