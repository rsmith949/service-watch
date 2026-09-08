cat > README.md <<'EOF'
# service-watch

External uptime and TLS certificate monitoring for self-hosted services.

## Why this exists

Monitoring your own infrastructure from inside that infrastructure is circular. If the
host goes down, the monitor goes down with it and tells you nothing. `service-watch` is
built to run somewhere else  a small container, off-premises, watching your services
from the outside and reporting only what it can actually reach.

It answers questions you otherwise learn about from a complaint:

- Is the service responding at all?
- Is the TLS certificate about to expire?

The second one is quieter than it sounds. Automated certificate renewal fails silently:
nothing breaks for weeks, and then everything breaks at once.

## What it checks

| Check | Reports |
|-------|---------|
| HTTP  | Status code and response time |
| TLS   | Days remaining before certificate expiry, warning under a configurable threshold |

A failing check exits non-zero, so the container composes with anything that reads exit
codes  cron, a shell script, a scheduler.

## Running it

    docker run --rm \
      -e WATCH_TARGETS=https://example.com,https://status.example.com \
      -e WATCH_WARN_DAYS=14 \
      service-watch:latest

## Configuration

All configuration comes from the environment. Nothing specific to any deployment is
committed to this repository.

| Variable          | Default | Meaning |
|-------------------|---------|---------|
| `WATCH_TARGETS`   | (none)  | Comma-separated list of URLs to check |
| `WATCH_WARN_DAYS` | `14`    | Warn when a certificate has fewer days than this remaining |

The default threshold is 14 rather than 30 deliberately. Let's Encrypt certificates last
90 days and renewal attempts begin at 30, so a certificate under 14 days means renewal
has already failed repeatedly  a real problem rather than a routine countdown.

## Pipeline

Every push runs lint, unit tests, and a container build on GitHub Actions. Merges to
`main` additionally publish an image to Amazon ECR, tagged with the commit SHA, so any
image can be traced to the source that produced it.

The pipeline authenticates to AWS using **OIDC federation**. It assumes an IAM role
scoped to this repository and branch, receives credentials that expire within the hour,
and stores no access keys anywhere. The attached IAM policy permits pushing to exactly
one ECR repository and nothing else.

## Development

    python3 -m venv .venv && source .venv/bin/activate
    pip install -r requirements.lock.txt -r requirements-dev.txt
    python -m pytest -q
    ruff check .

The test suite makes no network calls. HTTP behavior is exercised with test doubles, and
the system clock is injected rather than read, so certificate-expiry logic is
deterministic instead of depending on the date the suite happens to run.

## Roadmap

- Deploy to EC2 and run on a schedule
- Provision infrastructure with Terraform
- Alert via SNS
- DNS drift detection, to distinguish a stale dynamic-DNS record from a genuine outage
- Trivy image scan as a required pipeline gate
EOF
ls -la README.md
