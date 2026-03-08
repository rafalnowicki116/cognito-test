---
name: python-project-structure
description: Design Python package structure with clear module boundaries and explicit public interfaces.
compatibility: opencode
---

## When to use
Use when creating or refactoring Python module and package structure.

## Core principles
- You always use python3.10 or later.
- Keep modules cohesive: group code that changes together.
- Keep interfaces explicit: export public API via `__init__.py` and `__all__`.
- Prefer flat hierarchies; add depth only for real sub-domains.
- Apply naming and layout conventions consistently.

## Structure rules
- Keep the repository root simple and explicit; common top-level directories are `src/`, `tests/`, `infrastructure/`, `docs/`, and `scripts/`.
- Keep application code under `src/<package_name>/`.
- Start small and grow in layers: begin with a few cohesive modules, then add `services`, `repositories`, `models`, `adapters`, `api`, `config` only when the codebase needs them.
- Prefer a layered layout for larger projects: `api`, `services`, `repositories`, `models`, `adapters`, `interfaces`, `config`.
- Keep one concept per file; split files that mix unrelated responsibilities.
- Keep dependency flow one-way: `api -> services -> repositories/adapters`.
- Keep domain logic in `services`; keep I/O and integration in `repositories` and `adapters`.

## What belongs at the root
- Keep Python application code in `src/`.
- Keep automated tests in `tests/`.
- Keep infrastructure and deployment code in `infrastructure/`.
- Keep human-facing documentation in `docs/`.
- Keep developer helper scripts in `scripts/`.

## What does not belong in the package
- Do not place Terraform, CI configuration, deployment manifests, or operational scripts under `src/<package_name>/`.
- Do not place documentation files inside the Python package unless they are shipped as package data for a real runtime need.
- Do not mix editor, tool, or repository metadata into application modules.
- Keep the Python package focused on importable application code.

## Growth path
- For very small packages, a flat structure under `src/<package_name>/` is acceptable.
- When multiple use cases appear, introduce `services/` first and move domain behavior there.
- Add `repositories/` when persistent storage or database access appears.
- Add `api/` for HTTP, CLI, or event entrypoints.
- Add `adapters/` for external systems such as AWS, queues, or third-party APIs.
- Avoid creating empty layers in advance just to match a template.

## Recommended repository layouts

### Single app

```text
docs/
infrastructure/
src/
  example_project/
    __init__.py
    services/
    adapters/
    repositories/
    api/
    config/
tests/
  services/
  adapters/
scripts/
pyproject.toml
uv.lock
```

### Monorepo-lite

```text
apps/
  api/
    src/
    tests/
  worker/
    src/
    tests/
libs/
  shared/
infrastructure/
docs/
pyproject.toml
```

- For a single Python application, prefer `src/` and `tests/` directly at the repository root.
- Use a higher-level container such as `apps/` only when the repository truly contains multiple applications or deployable units.

## Module and import rules
- Use `snake_case` for module names.
- Match file names to intent (for example `user_service.py`, `order_repository.py`).
- Use absolute imports from the top-level package.
- Do not leak internal modules through accidental wildcard imports.

## Test placement
- Keep tests in `tests/` and mirror the `src/` structure.
- Keep test naming consistent: `test_<module>.py`.
- As the project grows, move tests from flat files like `tests/test_core.py` to mirrored paths such as `tests/services/test_greeting_service.py`.
- Keep shared fixtures in local `conftest.py` files close to consuming tests.

## Anti-patterns
- Avoid kitchen-sink modules with mixed responsibilities.
- Avoid deep technical nesting without domain value.
- Avoid circular imports by keeping boundaries explicit.
- Avoid vague catch-all modules such as `utils.py`, `helpers.py`, or `common.py` when a more specific name would reveal intent.

## Validation
- `uv run ruff check .`
- `uv run pytest -q`

## Definition of done
- Structure is discoverable and consistent across packages.
- Public API boundaries are explicit.
- Imports are stable and free from circular dependencies.
