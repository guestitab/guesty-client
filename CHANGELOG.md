# Changelog

## [Unreleased]

## [0.1.0] - 2026-11-08

First release as `guesty-client`, extracted from the Guesty integration Guestit runs in production. The specs are
that integration's provider specs, ported with their recorded VCR cassettes.

### Added

- `Guesty.configure` for credentials per priority lane, the token store, the rate limiter, the slot picker, custom
  field ids and the default currency. No Rails dependency.
- Wire API on the `Guesty` module: `connection`, `do_request` with retries of known Guesty glitches, `with_priority`
  lanes, credential slots (`token_slots`, `pick_slot`), the error helpers `retryable_read?`, `unapplied?` and
  `delivery_unknown?`, and `webhook_key`.
- Rate limits of 10 requests a second, 120 a minute and 5,000 an hour per credential slot.
- `sig/guesty.rbs` declaring the public API.
- Operations, each returning a dry-monads `Result`:
  - `AccessTokens::Upsert`: OAuth client-credentials token, one stored token per slot.
  - Reservations: `Search`, `Show`, `Create`, `Update`, `Recover`, `Approve`, `Decline`, `PreApprove`,
    `Status::Update`, `Status::Cancel`, `Dates::Update`, `Stays::Update`, `Flags::Update`,
    `AccommodationFare::Update`, `CustomFields::Update`, `Payments::Create`.
  - Conversations: `Index`, `Show`, `Search`, `Posts::Index`, `Posts::Since`, `Messages::Reply`,
    `Attachments::Index`, and the `Conversations.channel` and `Reservations.from_conversation` helpers.
  - Reviews: `Reviews::Respond` and `Reservations::Reviews::Index` with extractors for Airbnb, Booking.com and Vrbo.
  - Guests: `Profiles::Create`, `Profiles::Show`, `Profiles::Update`.
  - Homes: `Search`, `Calendars::Show`.
  - `GuestFolio::InvoiceItems::Index` for Airbnb Resolution Center items.
  - Webhooks: `Index`, `Create`, `Update`, `Sync`, `Signatures::Verify` for Svix signatures.
  - Views: `Create`, `Update`.

[Unreleased]: https://github.com/guestitab/guesty-client/compare/v0.1.0...staging
[0.1.0]: https://github.com/guestitab/guesty-client/releases/tag/v0.1.0
