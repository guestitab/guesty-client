# Repository Guidelines

`guesty-client` (module `Guesty`, `require 'guesty'`) is a host-agnostic Ruby client for the Guesty Open API,
extracted from the Guestit core app and published on RubyGems. It has no Rails dependency; the host injects
credentials, a token store, a rate limiter and a slot picker via `Guesty.configure`. README is the public guide and
holds the release steps.

## Project Structure

- `lib/guesty.rb` — entry point: requires, and the `Guesty.configure`/`Guesty.config` accessors.
- `lib/guesty/client.rb` — the module-level wire API: `Guesty.connection`, `Guesty.do_request`,
  priority/slot handling (`with_priority`, `current_slot`, `pick_slot`), response and error
  classification (`successful_response?`, `retryable_read?`, `unapplied?`, `delivery_unknown?`).
- `lib/guesty/rate_limiter_middleware.rb` — Faraday middleware; throttling policy lives in the
  injected `Guesty.config.rate_limiter` (`Guesty::MemoryRateLimiter` by default).
- `lib/guesty/config.rb` — injected `credentials` (priority slots + `webhook_key`), `token_store`,
  `rate_limiter`, `slot_picker`, `base_url`, `sync_guest_and_reservation_changes`.
- `lib/guesty/operation.rb` — the monadic base (`#call` returns a Result, `#call!` unwraps/raises).
- `lib/guesty/<resource>/<action>.rb` — one operation per file, namespaced `Guesty::<Resource>::<Action>`.
- `spec/` — RSpec + VCR; cassettes in `spec/fixtures/cassettes`.

## Boundary

- Payload ↔ domain mappers stay in the host (`Reservations::Payloads::Import` / `Render` in core):
  they translate domain statuses, channels and currencies, which is host vocabulary. The gem speaks
  wire vocabulary only.
- Token persistence stays in the host (core's encrypted `guesty_access_tokens` table), behind the
  injected `token_store`.
- Error reporting stays in the host: an operation returns `Failure(error)`; the host's operation
  wrapper decides what to report.

## Build, Test, and Development Commands

- Setup: `bundle install`.
- Test: `bundle exec rspec` (offline, VCR-backed) or `bundle exec rake` (spec + rubocop).
- Lint: `bundle exec rubocop` (or `-A` to autocorrect — review every change).

## Coding Style & Conventions

- Ruby: 2-space indent; `snake_case` methods/vars; `CamelCase` classes.
- Operations: `Guesty::<Resource>::<Action>`, `include Guesty::Operation`, `def call(...)`,
  return `Dry::Monads::Result`, invoke with a fresh instance (`Op.new.call(...)` / `Op.new.call!(...)`).
- Validate arguments up front with `argument!` (e.g. `argument! reservation_id: :required`) before
  any network call.
- Send each request with the private `request(method, path, params, **options)`: it returns the parsed
  body and raises a rejection's `ApiError`, which `#call` returns as the `Failure`. Wrap the value in
  `Success(...)`.
- Keep all HTTP and response normalization in `Guesty`'s module functions and the operations; never
  leak wire decisions past the operation boundary.
- No `Rails`, no app constants — the gem stays framework-free (host injects config). ActiveSupport
  core extensions are fine.
- Guesty behaviour notes live in the `guesty` skill (`.agents/skills/guesty`); read it before
  changing endpoints, webhooks or token handling.

## Testing Guidelines

- Stack: RSpec + VCR + WebMock. Specs run offline against recorded cassettes ported from core
  (`spec/fixtures/cassettes/lib/channel_managers/guesty` there maps to `spec/fixtures/cassettes` here).
- Configure `Guesty` in the `spec_helper` `before` hook with the cassette-matching test credentials
  (`[GUESTY_DEFAULT_0_CLIENT_ID]` etc.) and a memory token store holding a live token.
- Mirror the source tree: `spec/guesty/<resource>/<action>_spec.rb`.

## Commit & Pull Request Guidelines

- Commits: short, imperative subject with a conventional prefix: `feat:`, `fix:`, `chore:`,
  `dev:`, `misc:`, `test:`, `docs:`. Use scoped subjects when useful (e.g., `feat(reservations): …`).
- PRs: clear description, linked issues, and a brief test plan. Ensure `bundle exec rake` passes.
- `staging` is the default branch; `production` tracks released gems.
