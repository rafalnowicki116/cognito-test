---
name: vue-frontend-typescript
description: Build modern Vue 3 frontends with Composition API, script setup, TypeScript, and pragmatic testing.
compatibility: opencode
---

## When to use
Use when creating or refactoring Vue frontend code, components, composables, stores, routing, or frontend tests.

## Recommended stack
- Vue 3
- Composition API
- `script setup`
- TypeScript by default
- Vite for build tooling
- Pinia for shared client-side state
- Vue Router for navigation
- Vitest + Vue Test Utils + Testing Library for unit and component tests
- Playwright for end-to-end tests when full browser flows matter

## Core principles
- Prefer Vue 3 Composition API over Options API for new code.
- Prefer `script setup lang="ts"` for components.
- Use TypeScript anywhere it improves safety, contracts, and refactoring confidence.
- Keep components focused on presentation and user interaction.
- Move reusable logic into composables.
- Keep data flow explicit through props, emits, stores, and composables.
- Prefer simple components and composables over clever abstractions.

## Architecture guidance
- Use components for rendering and interaction logic close to the template.
- Use composables for reusable stateful UI logic or async workflows.
- Use stores only for state that is truly shared across features or screens.
- Use services or API clients for HTTP calls and backend integration details.
- Keep route components thin; delegate substantial logic to composables, stores, or services.
- Prefer feature-oriented boundaries when the app grows, but do not create empty layers in advance.

## Recommended project structure

```text
src/
  app/
    router/
    providers/
  components/
    base/
  features/
    orders/
      components/
      composables/
      services/
      stores/
      types/
      views/
  composables/
  services/
  stores/
  types/
  utils/
tests/
  unit/
  component/
  e2e/
```

- Start simple if the app is small.
- Move toward `features/` when the codebase grows beyond a few screens.
- Keep shared UI in `components/` and shared logic in `composables/` only when reused by multiple features.
- Keep `utils/` small and specific; avoid turning it into a dumping ground.

## Component rules
- Keep one component responsible for one clear UI concern.
- Type props and emits explicitly.
- Prefer computed state over template-heavy inline expressions.
- Keep business rules out of templates.
- Prefer slots over deeply nested prop combinations for extensibility.
- Do not access global state directly in every component when props or composables would keep dependencies clearer.

## TypeScript rules
- Use `lang="ts"` in components by default.
- Type props with interfaces or inline type literals.
- Type emits explicitly.
- Type API responses and domain models in dedicated `types/` modules.
- Prefer `unknown` over `any` when data shape is not yet trusted.
- Avoid `as` casts unless they are truly necessary and safe.

## State management rules
- Use local component state first.
- Promote state into a composable when multiple components need the same UI behavior.
- Promote state into Pinia only when it is genuinely cross-feature, cross-route, or session-like state.
- Keep Pinia stores focused and domain-oriented, not generic.
- Do not turn Pinia into a second backend cache for everything by default.

## Async data and API rules
- Keep HTTP clients and request details in `services/` or feature services.
- Map backend payloads into frontend-friendly shapes close to the API boundary when useful.
- Keep loading, error, and empty states explicit in the UI.
- Cancel, debounce, or guard repeated requests when user interaction can trigger them rapidly.
- Keep route-level data fetching simple and predictable.

## Testing strategy
- Test composables and pure helpers with unit tests.
- Test components through rendered behavior, user interaction, emitted events, and visible state.
- Test stores through public actions and state changes.
- Mock network and external boundaries, not internal implementation details.
- Use Playwright only for high-value user flows that need real browser confidence.

## Test style guidance
- Prefer self-descriptive test names.
- Structure tests with `Given / When / Then` comments when it improves readability.
- Keep component tests focused on what the user can observe.
- Avoid asserting internal refs, private variables, or exact implementation order unless behavior depends on it.

## Lightweight examples

### Component

```vue
<script setup lang="ts">
interface Props {
  name: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  greeted: [name: string]
}>()

function onClick(): void {
  emit('greeted', props.name)
}
</script>

<template>
  <button type="button" @click="onClick">
    Greet {{ props.name }}
  </button>
</template>
```

### Composable

```ts
import { ref } from 'vue'

export function useGreeting() {
  const message = ref('')

  function greet(name: string): void {
    message.value = `Hello, ${name}!`
  }

  return {
    greet,
    message,
  }
}
```

### Pinia store

```ts
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useSessionStore = defineStore('session', () => {
  const userId = ref<string | null>(null)

  function setUser(id: string | null): void {
    userId.value = id
  }

  return {
    setUser,
    userId,
  }
})
```

### Component test

```ts
import { render, screen } from '@testing-library/vue'
import userEvent from '@testing-library/user-event'
import GreetingButton from './GreetingButton.vue'

test('emits greeted event with the provided name', async () => {
  // Given
  const user = userEvent.setup()
  const { emitted } = render(GreetingButton, {
    props: { name: 'Alice' },
  })

  // When
  await user.click(screen.getByRole('button', { name: 'Greet Alice' }))

  // Then
  expect(emitted().greeted).toEqual([['Alice']])
})
```

### Composable test

```ts
import { useGreeting } from './useGreeting'

test('updates the greeting message for the provided name', () => {
  // Given
  const { greet, message } = useGreeting()

  // When
  greet('Alice')

  // Then
  expect(message.value).toBe('Hello, Alice!')
})
```

## Anti-patterns - DON'T DO IT!!!
- Use Options API for new code unless the existing codebase already standardizes on it.
- Put large business workflows directly inside view components.
- Fetch data directly from random components when a service or composable should own that boundary.
- Put every state value into Pinia just because it might be reused later.
- Use `any` broadly instead of modeling data with TypeScript types.
- Create giant components that mix layout, API calls, business rules, and store orchestration.
- Test internal implementation details instead of rendered behavior and public outcomes.
- Mix multiple architectural styles in the same feature without a clear reason.

## Definition of done
- Components, composables, stores, and services have clear responsibilities.
- TypeScript contracts are explicit where they improve safety and maintainability.
- Tests cover user-visible behavior and public state transitions.
- The structure stays understandable as the frontend grows.

## Validation
- `npm run typecheck`
- `npm run test`
- `npm run build`
- If the project uses `pnpm` or `yarn`, use the equivalent commands consistently.
