# Guesty

`guesty` is a host-agnostic Ruby client for the [Guesty Open API](https://open-api-docs.guesty.com/),
extracted from the Guestit core app. It has no Rails dependency; the host injects
credentials, a token store, a rate limiter and a slot picker via `Guesty.configure`.

## Installation

```ruby
gem 'guesty'
```

## Configuration

```ruby
Guesty.configure do |config|
  config.credentials = {
    default: [{ client_id: '...', secret: '...' }],   # several entries enable round-robin slots
    high:    [{ client_id: '...', secret: '...' }],   # priority lane for user-triggered writes
    webhook_key: 'whsec_...'
  }
  config.token_store = MyTokenStore.new               # default: Guesty::MemoryTokenStore
  config.rate_limiter = MyRateLimiter.new             # default: Guesty::MemoryRateLimiter
  config.slot_picker = ->(slots, priority) { ... }    # default: first slot
end
```

A token store responds to `read(slot_key)` and `save(slot_key:, access_token:, expires_at:)`.
A rate limiter responds to `throttle!(key:, threshold:, interval:)` and raises
`Guesty::ThrottledError` when the window is full.

## Usage

One operation per endpoint, namespaced `Guesty::<Resource>::<Action>`:

```ruby
Guesty::Reservations::Show.new.call(reservation_id:, fields: %w[_id listing._id])
# => Success({ _id: ..., ... })

Guesty.with_priority(:high) do
  Guesty::Reservations::Status::Update.new.call(...)
end
```

## Development

- Setup: `bundle install`
- Test: `bundle exec rspec` (offline, VCR-backed) or `bundle exec rake` (spec + rubocop)
- Lint: `bundle exec rubocop`
