# guesty-client

A Ruby client for the [Guesty Open API](https://open-api-docs.guesty.com/). Each endpoint is one operation class that
returns a [dry-monads](https://dry-rb.org/gems/dry-monads/) `Result`. The gem handles OAuth tokens, rate limits,
retries and webhook signatures. It does not depend on Rails, only on ActiveSupport and Faraday. Your app supplies the
credentials, the token storage and the rate limiter.

[Guestit](https://guestit.se) built it and runs it in production.

Requires Ruby 4.0 or later.

## Installation

```ruby
# Gemfile
gem 'guesty-client'
```

Bundler loads it for you. Outside Bundler, `require 'guesty'`.

## Configuration

```ruby
Guesty.configure do |config|
  config.credentials = {
    default: [
      { client_id: ENV.fetch('GUESTY_CLIENT_ID'), secret: ENV.fetch('GUESTY_CLIENT_SECRET') }
    ],
    high: [
      { client_id: ENV.fetch('GUESTY_HIGH_CLIENT_ID'), secret: ENV.fetch('GUESTY_HIGH_CLIENT_SECRET') }
    ],
    webhook_key: ENV.fetch('GUESTY_WEBHOOK_KEY')
  }
  config.token_store = MyTokenStore.new
  config.rate_limiter = MyRateLimiter.new
end
```

| Setting | Default | What it does |
| --- | --- | --- |
| `credentials` | `{}` | Client credentials per priority lane, plus the webhook signing key. |
| `token_store` | `Guesty::MemoryTokenStore` | Holds one access token per credential slot. |
| `rate_limiter` | `Guesty::MemoryRateLimiter` | Counts requests per slot and window. |
| `slot_picker` | first slot | `->(slots, priority) { slot }`, called when a lane has several credentials. |
| `custom_fields` | `{}` | Account custom field ids by flag name, read by `Reservations::Flags::Update`. |
| `default_currency` | `nil` | When set, `Homes::Calendars::Show` refuses a calendar priced in another currency. |
| `base_url` | `https://open-api.guesty.com/v1/` | API root. |

### Access tokens

Guesty mints 5 access tokens per client id per 24 hours and answers 429 to every request after that. The default
memory store loses its tokens when the process exits, so it suits a console or a single long-running process. Once
you run more than one process, or restart often, inject a shared store that keeps each token until it expires:

```ruby
class MyTokenStore
  # Returns an object that responds to #access_token, or nil when no live token is stored.
  def read(slot_key); end

  # Persists the token and returns an object that responds to #access_token.
  def save(slot_key:, access_token:, expires_at:); end
end
```

### Rate limits

Every request passes three windows per credential slot: 10 a second, 120 a minute and 5,000 an hour. The limiter
raises `Guesty::ThrottledError` when a window is full, and the request is never sent. The memory limiter counts per
process. With several processes, inject one backed by Redis or your cache:

```ruby
class MyRateLimiter
  # Raises Guesty::ThrottledError.new(key:, threshold:, interval:, retry_after:) once
  # more than threshold calls arrive for key within interval.
  def throttle!(key:, threshold:, interval:); end
end
```

### Priority lanes and slots

Each key in `credentials` other than `webhook_key` is a lane. Requests run on `:default` unless wrapped:

```ruby
Guesty.with_priority(:high) do
  Guesty::Reservations::Approve.new.call(reservation_id:)
end
```

A lane with several credentials gets one slot per credential. Each slot has its own token and rate limit windows, and
`slot_picker` chooses the slot for each request.

## Usage

Operations live under `Guesty::<Resource>::<Action>`. Build a fresh instance for every call:

```ruby
result = Guesty::Reservations::Show.new.call(reservation_id: '67ebc9c7c5904c0010502f89')

if result.success?
  result.value!   # => { _id: '67ebc9c7c5904c0010502f89', status: 'confirmed', stay: [...], ... }
else
  result.failure  # => a Guesty::Error or a Faraday::Error
end
```

`call` never raises. It returns `Success(value)` or `Failure(error)`. `call!` returns the `Success` and raises the
error where `call` would return a `Failure`. Response bodies come back as hashes with symbol keys.

The gem covers reservations (search, create, update, approve, decline, cancel, payments, custom fields, reviews),
conversations and messages, guest profiles, listings and calendars, guest folio items, review responses, webhooks and
saved views. [CHANGELOG.md](CHANGELOG.md) lists every operation.

### Errors

| Class | Raised when |
| --- | --- |
| `Guesty::ArgumentError` | The arguments are unusable. Raised before any request. |
| `Guesty::ApiError` | Guesty answered with an error, including one tunnelled through an HTTP 200. `#status` and `#raw_body` hold the details. |
| `Guesty::ThrottledError` | The rate limiter refused the request. Nothing was sent. |
| `Guesty::Error` | The parent of the three above, also raised for refusals inside an operation. |

`error.fatal` is true for a refusal that no retry can fix.

### Retries

The client retries a 429 and network failures with backoff on every method but POST. Reads also retry the known Guesty
errors that a second attempt fixes; operations that must not write twice send once. After a failed write, these
helpers tell you what happened:

```ruby
Guesty.unapplied?(error)        # the write certainly did not take, so a retry is safe
Guesty.delivery_unknown?(error) # it may have taken, so read back before retrying
Guesty.retryable_read?(error)   # a read failed for a reason a retry can fix
```

### Webhooks

Guesty sends webhooks through Svix. Verify each delivery against the raw body and its headers before trusting it:

```ruby
Guesty::Webhooks::Signatures::Verify.new.call(payload: request.raw_post, headers: request.headers)
# => Success(true), or a Failure when no signature matches or the timestamp is more than 5 minutes off
```

`Guesty::Webhooks::Sync.new.call(urls:, events:)` subscribes each url to the events. It creates missing webhooks,
updates drifted ones and returns the urls grouped by `:created`, `:updated` and `:unchanged`.

## Type signatures

The gem ships RBS for its public API in `sig/guesty.rbs`. `rbs collection install` picks it up from your
`Gemfile.lock`, so Steep sees it with no extra setup.

## Development

```sh
bundle install
bundle exec rake        # specs and RuboCop
bundle exec rspec       # specs only
bundle exec rubocop -A  # autocorrect; review every change
```

The specs run offline against recorded VCR cassettes in `spec/fixtures/cassettes`. Recording a new cassette needs
live credentials for a Guesty account. Scrub tokens, guest names and contact details from the cassette before you
commit it.

## Releasing

1. Bump `Guesty::VERSION` in `lib/guesty/version.rb` and move the `Unreleased` notes in `CHANGELOG.md` under the new
   version.
2. Commit on `staging` and run `bundle exec rake`.
3. Run `gem signin` once per machine. The gem requires MFA, so every push asks for a one-time code.
4. Run `bundle exec rake release`. It builds `pkg/guesty-client-<version>.gem`, tags `v<version>`, pushes the branch
   and the tag, and pushes the gem to RubyGems.
5. Fast-forward `production` to the release tag.

## License

MIT. See [LICENSE](LICENSE).
