---
name: python-design-patterns
description: Apply pragmatic Python design patterns and abstraction decisions with clear boundaries.
compatibility: opencode
---

## When to use
Use when designing architecture, introducing abstractions, or refactoring complex code.

## Core principles
- Prefer the simplest solution that works (KISS).
- Follow SOLID, especially SRP and dependency inversion.
- Keep strict separation of concerns between layers.
- Prefer composition over inheritance.
- Use inheritance sparingly; choose it only when there is a real is-a relationship and shared behavior cannot be expressed more clearly through composition.
- Follow the Rule of Three before introducing shared abstractions.
- Prefer explicit and readable code over clever indirection.

## Abstraction rules
- Start with a simple concrete implementation.
- Introduce abstractions only when there is repeated variability or a clear test boundary need.
- Use interfaces via `Protocol` or `ABC` for extension points.
- Prefer `Protocol` for lightweight structural typing and test seams; use `ABC` when you need shared base behavior, explicit inheritance, or enforced abstract methods at runtime.
- Use generics (`TypeVar`, generic classes) only when they improve reuse and typing clarity.
- Delete dead code before adding new abstractions.

## Choosing common building blocks
- Use a `service` when business rules or orchestration span multiple steps or dependencies.
- Use a `repository` when the main responsibility is loading or persisting domain data.
- Use an `adapter` when wrapping an external SDK, HTTP API, queue, filesystem, or other infrastructure detail.
- Use a `facade` when callers need a simpler entrypoint over several services or adapters.
- Keep `service` code free from transport and SDK details; inject repositories and adapters instead.
- Do not turn every helper into a pattern; prefer plain functions until a clear boundary appears.

## Quick selection guide
- Choose `service` for domain workflows like `create_order`, `send_invoice`, or `calculate_discount`.
- Choose `repository` for persistence-facing operations like `get_user_by_id` or `save_order`.
- Choose `adapter` for infrastructure-facing operations like `publish_event`, `send_email`, or `fetch_exchange_rates`.
- Choose `facade` when the caller should not coordinate 3-4 lower-level collaborators directly.
- If a class both applies business rules and calls an SDK directly, split it into `service` + `adapter`.

## Lightweight examples
- `service`: `OrderService.place_order()` validates input, checks stock, calculates totals, and coordinates repository and adapter calls.
- `repository`: `OrderRepository.save(order)` persists and loads `Order` data without business decisions.
- `adapter`: `StripePaymentAdapter.charge(...)` wraps the Stripe SDK and maps SDK exceptions into local exceptions.
- `facade`: `CheckoutFacade.checkout(...)` gives the caller one entrypoint over payment, inventory, and notification steps.

## Python mini-snippets

### Service

```python
class OrderService:
    def __init__(self, repository: OrderRepository, payments: PaymentAdapter) -> None:
        self._repository = repository
        self._payments = payments

    def place_order(self, order: Order) -> None:
        if not order.items:
            raise ValueError("order must contain items")
        self._payments.charge(order.total)
        self._repository.save(order)
```

### Repository

```python
class OrderRepository:
    def save(self, order: Order) -> None:
        self._session.add(order)
        self._session.commit()

    def get_by_id(self, order_id: str) -> Order | None:
        return self._session.get(Order, order_id)
```

### Adapter

```python
class StripePaymentAdapter:
    def __init__(self, client: StripeClient) -> None:
        self._client = client

    def charge(self, amount: int) -> None:
        try:
            self._client.charge(amount=amount)
        except StripeError as exc:
            raise PaymentFailedError("stripe charge failed") from exc
```

### Facade

```python
class CheckoutFacade:
    def __init__(self, orders: OrderService, notifications: NotificationAdapter) -> None:
        self._orders = orders
        self._notifications = notifications

    def checkout(self, order: Order) -> None:
        self._orders.place_order(order)
        self._notifications.send_confirmation(order.customer_email)
```

### Strategy

```python
class DiscountStrategy(Protocol):
    def apply(self, total: int) -> int: ...


class NoDiscount:
    def apply(self, total: int) -> int:
        return total


class LoyaltyDiscount:
    def apply(self, total: int) -> int:
        return int(total * 0.9)
```

### Factory

```python
class PaymentAdapterFactory:
    def create(self, provider: str) -> PaymentAdapter:
        if provider == "stripe":
            return StripePaymentAdapter(StripeClient())
        if provider == "dummy":
            return DummyPaymentAdapter()
        raise ValueError(f"unsupported provider: {provider}")
```

### Decorator

```python
class LoggingPaymentAdapter:
    def __init__(self, wrapped: PaymentAdapter, logger: logging.Logger) -> None:
        self._wrapped = wrapped
        self._logger = logger

    def charge(self, amount: int) -> None:
        self._logger.info("charging payment", extra={"amount": amount})
        self._wrapped.charge(amount)
```

## Preferred patterns

- Use this page as a main reference: https://refactoring.guru/pl/design-patterns
- Facade
- Factory
- Dependency Injection
- Adapter
- Strategy
- Builder
- Repository
- Unit of Work (only when a real transaction boundary is required)
- Specification
- Template Method
- Observer
- Decorator
- Command
- Chain of Responsibility

## Pattern examples from the reference site
- Use the linked reference for implementation examples and trade-offs: https://refactoring.guru/pl/design-patterns
- `Adapter`: when an external SDK interface does not match your application boundary.
- `Strategy`: when one workflow needs swappable variants such as pricing, discount, or retry policy.
- `Factory`: when object creation depends on config, environment, or selected provider.
- `Facade`: when several lower-level collaborators should be hidden behind one simpler API.
- `Decorator`: when you want to add cross-cutting behavior like logging, caching, or metrics without changing core logic.

## Boundary rules
- Keep layer flow one-way: `api/handler -> service -> repository/adapter`.
- Keep handlers focused on transport concerns (parse, validate, map response).
- Keep services focused on business rules and orchestration.
- Keep repositories/adapters focused on I/O and integration details.
- Do not leak internal ORM or infrastructure models across boundaries.
- Do not mix SQL/HTTP SDK calls directly into core business logic.

## Anti-patterns
- Premature abstraction before the third real use case.
- Deep inheritance trees for behavior composition.
- Pattern stacking without clear value.
- Kitchen-sink classes that mix transport, business logic, and data access.
- Global mutable state or hidden singletons that hurt testability.

## Definition of done
- Chosen abstraction is justified against a simpler alternative.
- Layer boundaries are preserved and easy to reason about.
- Components are testable in isolation via injected dependencies.

## Validation
- `uv run ruff check .`
- `uv run pytest -q`
