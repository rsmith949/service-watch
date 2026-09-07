"""Entrypoint: run every check once and print the results."""

from urllib.parse import urlparse

from app.checks import check_http, check_tls
from app.config import Settings


def main() -> int:
    settings = Settings()
    targets = settings.target_list()

    if not targets:
        print("No targets configured. Set WATCH_TARGETS.")
        return 1

    failures = 0
    for url in targets:
        hostname = urlparse(url).hostname
        results = [check_http(url)]
        if url.startswith("https://") and hostname:
            results.append(check_tls(hostname, warn_days=settings.warn_days))
        for result in results:
            status = "OK  " if result.ok else "FAIL"
            latency = f" ({result.latency_ms}ms)" if result.latency_ms else ""
            print(f"{status} {url} [{result.name}] {result.detail}{latency}")
            if not result.ok:
                failures += 1

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
