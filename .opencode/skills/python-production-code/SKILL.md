---
name: python-production-code
description: Build resilient production Python code with explicit error handling, retries, and observability.
compatibility: opencode
---

## When to use
Use for production-facing services, integrations, and reliability hardening.

## Layer roles
- Keep `services` focused on business rules, orchestration, and idempotent workflow decisions.
- Keep `adapters` focused on external SDKs, HTTP APIs, queues, filesystems, and error mapping.
- Keep `repositories` focused on persistence and retrieval of application data.
- Create external clients through a dedicated factory/provider and inject them into services or adapters.

## Code quality baseline
- Use type hints for all public functions, methods, and return values.
- Add docstrings for public modules, classes, and functions.
- Keep imports ordered (stdlib, third-party, local).
- Use `logging`; do not use `print` for runtime diagnostics.

## Reliability rules
- Define a custom exception hierarchy.
- Map SDK/HTTP errors at adapter boundaries.
- Retry only transient failures (`429`, timeouts, `5xx`, connection resets) with exponential backoff, jitter, explicit retry limits, and retry logging that includes attempt number and delay.
- Do not retry validation or business-rule failures.
- Use explicit request timeouts for all external calls.

## Client and configuration management
- Create external clients through a dedicated factory/provider and inject them.
- Reuse long-lived clients where safe instead of recreating clients per call.
- Keep URLs, secrets, and credentials in environment/config, never hardcoded.
- Keep production defaults safe and explicit (timeouts, retry caps, feature flags).
- Read environment variables in one configuration layer, not throughout the codebase.
- Prefer `config/settings.py` or an equivalent single settings module for parsing and validation.

## Observability rules
- Keep logs structured and actionable.
- Include context fields when available (`request_id`, `correlation_id`, `entity_id`, operation).
- Configure logging in the application entrypoint; libraries should only create module loggers.
- Log at `info` for expected state changes, `warning` for recoverable anomalies, and `exception` for unexpected failures with stack traces.
- Do not log secrets, tokens, full credentials, or sensitive personal data.

## Data and API efficiency
- Filter server-side whenever possible.
- Fetch only required fields.
- Apply projection/select semantics where available.
- Use sorting and limits for deterministic reads.
- Use pagination for large reads.

## Operational behavior
- Prefer idempotent writes for retried workflows.
- Keep side effects explicit and compensate or rollback on partial failure where needed.
- Use idempotency keys, request IDs, or deduplication markers when the same command may be retried.

## Lightweight examples

### Exception hierarchy

```python
class PaymentError(Exception):
    """Base payment error."""


class PaymentTemporaryError(PaymentError):
    """Retryable payment error."""


class PaymentFailedError(PaymentError):
    """Non-retryable payment error."""
```

### Adapter with timeout and error mapping

```python
class StripePaymentAdapter:
    def __init__(self, client: StripeClient) -> None:
        self._client = client

    def charge(self, amount: int) -> None:
        try:
            self._client.charge(amount=amount, timeout=5)
        except StripeRateLimitError as exc:
            raise PaymentTemporaryError("stripe rate limited") from exc
        except StripeError as exc:
            raise PaymentFailedError("stripe charge failed") from exc
```

### Client factory

```python
def build_stripe_client(settings: Settings) -> StripeClient:
    return StripeClient(api_key=settings.stripe_api_key, base_url=settings.stripe_base_url)
```

### Retry wrapper

```python
def charge_with_retry(adapter: StripePaymentAdapter, amount: int) -> None:
    for attempt in range(1, 4):
        try:
            adapter.charge(amount)
            return
        except PaymentTemporaryError:
            if attempt == 3:
                raise
            time.sleep(0.25 * attempt)
```

## Validation
- `uv run ruff check .`
- `uv run pytest -q`
- Add unit tests for timeout, retry, and error-mapping behavior.

## Definition of done
- Failure modes are handled and logged with actionable context.
- External calls have explicit timeout and retry behavior.
- No hardcoded secrets or environment-specific endpoints.

## Anti-patterns - DON'T DO IT!!!
- Catch `Exception` broadly in application code when you can handle specific failure types.
- Rely on SDK default timeouts or omit timeouts entirely.
- Retry validation failures, business-rule failures, or permanent `4xx` errors.
- Read `os.environ` in random services and adapters; centralize config loading.
- Log secrets, tokens, passwords, or full request bodies with sensitive data.
- Call external SDKs directly from business services when an adapter boundary should own that integration.
- Add unbounded retry loops with no cap, no jitter, and no observability.
