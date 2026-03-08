---
name: python-unit-tests
description: Create fast, isolated Python unit tests with pytest and clear layer boundaries.
compatibility: opencode
---

## When to use
Use when adding or changing unit tests.

## Test design rules
- Use `pytest` as the test runner and discovery tool.
- Use plain `pytest` test functions and raw `assert` statements by default.
- Keep a clear Given-When-Then flow.
- Keep unit tests isolated from network and cloud services.
- Use fixtures to reduce duplication.
- Add regression tests for bug fixes.
- Mark tests consistently (`unit`, `integration`, `e2e`).

## Test boundary rules
- Test services with fakes/mocks for repositories and adapters.
- Keep handler/API tests focused on transport mapping and validation behavior.
- Keep repository/adapter tests in integration/e2e suites, not unit scope.
- Mirror the `src/` layout under `tests/`, for example `src/example_project/services/greeting_service.py` -> `tests/services/test_greeting_service.py`.
- Keep shared fixtures in the nearest `conftest.py` that serves more than one test module.
- Name each test file after the functionality under test so the target is obvious at a glance.

## Style guidance
- Prefer test functions over `unittest.TestCase` classes unless the repository already has a strong legacy `unittest` convention.
- Prefer direct `assert` checks because `pytest` gives rich failure diffs and readable output.
- Use `pytest.raises(...)` for exception assertions.
- Use `@pytest.mark.parametrize(...)` when the same behavior should be checked across multiple inputs.
- Use `conftest.py` only for fixtures shared by multiple test modules; keep one-off setup local to the test file.
- Structure tests in `Given / When / Then` style so setup, action, and expectation are easy to scan.
- Make each test name self-descriptive so the method explains the expected behavior without extra commentary.

## Anti-patterns
- Avoid real AWS, DB, or HTTP calls in unit tests.
- Avoid asserting private implementation details.
- Avoid brittle global state shared across test modules.
- Avoid overusing fixtures when plain local variables make the test easier to read.
- Avoid mixing `pytest` function tests with `unittest.TestCase` style in the same repository without a clear reason.

## Lightweight examples

Good file naming examples:
- `tests/services/test_greeting_service.py`
- `tests/services/test_order_service.py`
- `tests/adapters/test_stripe_payment_adapter.py`

```python
def test_greet_returns_hello_message_for_provided_name() -> None:
    # Given
    name = "Alice"

    # When
    result = greet(name)

    # Then
    assert result == "Hello, Alice!"
```

```python
@pytest.mark.parametrize(
    ("name", "expected"),
    [("Bob", "Hello, Bob!"), ("Charlie", "Hello, Charlie!")],
)
def test_greet_returns_expected_message_for_supported_names(name: str, expected: str) -> None:
    # When
    result = greet(name)

    # Then
    assert result == expected
```

```python
def test_place_order_raises_value_error_when_order_has_no_items(order_service: OrderService) -> None:
    # Given
    order = Order(items=[])

    # When / Then
    with pytest.raises(ValueError, match="order must contain items"):
        order_service.place_order(order)
```

```python
def test_place_order_saves_order_in_repository(
    order_service: OrderService,
    order_repository: FakeOrderRepository,
) -> None:
    # Given
    order = Order(items=[OrderItem("sku-1", quantity=1, price=100)])

    # When
    order_service.place_order(order)

    # Then
    assert order_repository.saved_orders == [order]
```

```python
def test_charge_raises_payment_failed_error_when_stripe_client_fails(
    payment_adapter: StripePaymentAdapter,
    failing_client: FakeStripeClient,
) -> None:
    # Given
    failing_client.should_fail = True

    # When / Then
    with pytest.raises(PaymentFailedError, match="stripe charge failed"):
        payment_adapter.charge(100)
```

## Naming and layout hints
- Keep file names aligned with the tested functionality, for example `test_greeting_service.py` for `greeting_service.py`.
- Keep test names behavior-oriented and self-explanatory, for example `test_greet_returns_hello_message_for_provided_name`.
- Prefer one clear `Given / When / Then` flow per test.
- If a test needs many `Given` sections or many `Then` assertions for unrelated outcomes, split it into smaller tests.

## Example template

```python
def test_behavior_name() -> None:
    # Given
    ...

    # When
    result = ...

    # Then
    assert result == ...
```
```

## Validation
- `uv run pytest tests/services -q --maxfail=1`
- `uv run pytest -q`

## Definition of done
- Unit tests are deterministic and isolated.
- New behavior and bug fixes include test coverage.
- Test names describe business intent, not implementation details.
- Test placement matches the application structure and is easy to navigate.
