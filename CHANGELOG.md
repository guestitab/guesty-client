# Changelog

## [Unreleased]

## [0.2.0] - 2026-11-10

Migrates the reservation surface off the legacy `/reservations` resources, which Guesty retires on
2027-03-01 (<https://open-api-docs.guesty.com/docs/reservation-migration>), and moves the pieces that spoke
Guestit's own vocabulary back into the host.

### Breaking

- `Reservations::Search` now reads `GET /reservations-v3/search`: the `fields:` keyword is gone (the payload
  is fixed and lean, keyed by `reservationId`; guest, money and conversationId are not embedded) and the
  result is `{ results:, pagination: }` with `pagination.hasMore` instead of `count`. Filters are
  `status`, `confirmation_code`, `listing_id`, `source` (one value or an Array) and `check_in`, `check_out`,
  `created_at` (a Ruby Range); `ids`, `updated_at` and `conversation_id` have no v3 equivalent.
- `Reservations::Show` now reads `GET /reservations-v3`: the `fields:` keyword is gone, and an unknown id
  fails with a fatal `Guesty::Error` instead of a 404 `Guesty::ApiError`. The v3 reservation embeds no
  `money`: read `hostPayout`, `totalPaid` and `currency` from `Payments::Index`.
- `Reservations::Update` and `Reservations::Stays::Update` are removed. The broad `PUT /reservations/{id}`
  is replaced by one endpoint per operation: `Status::Update`/`Status::Cancel`, `Dates::Update`,
  `CustomFields::Update` (all unchanged) plus the new `Guests::Update`, `ConfirmationCode::Update`,
  `Source::Update`, `BookingDate::Update` and `Relocate`.
- `Reservations::AccommodationFare::Update` reads the current fare from `GuestFolio::InvoiceItems::Index`
  instead of the legacy reservation's `money.invoiceItems`.
- Host vocabulary moves out of the gem, into the host:
  - `Reservations::Payments::Create` is removed. It was Guestit's idempotent record of a Stripe payment;
    compose `Payments::Index` and `Payments::Record` instead.
  - `Reservations::Flags::Update` and `config.custom_fields` are removed. Pass the account's field ids to
    `Reservations::CustomFields::Update`.
  - `config.sync_guest_and_reservation_changes` and `Guesty.sync_guest_and_reservation_changes?` are
    removed. The gem never read the flag.
  - `Conversations::Messages::Reply::BOOKING_MODULE_TYPES` and `.module_type_for` are removed. They mapped
    the host's channel names to Guesty module types.
- `Guesty::MemoryTokenStore#clear` is removed.

### Changed

- Every operation reads its response through one private `Operation#request`, which returns the parsed body
  and raises the `ApiError` that `#call` turns into the `Failure`. The failures are the same, with one
  exception: `Conversations::Index` now fails with the `Guesty::ApiError` itself instead of re-wrapping its
  message in a plain `Guesty::Error`.
- `Reservations::Show` reads through `Reservations::Index`.
- `Conversations.summary(conversation)` builds the `{ id:, reservations: }` hash that `Conversations::Index`,
  `Search` and `Show` return.

### Added

- `Reservations::Index`: up to 10 reservations by id from `GET /reservations-v3`.
- `Reservations::Guests::Update`: `PUT /reservations-v3/{id}/guests` (guestsCount + numberOfGuests).
- `Reservations::ConfirmationCode::Update`: `PUT /reservations-v3/{id}/confirmation-code`.
- `Reservations::Source::Update`: `PUT /reservations-v3/{id}/source`.
- `Reservations::BookingDate::Update`: `PUT /reservations-v3/{id}/booking-date` (the real-world booking
  date; `createdAt` stays canonical for Guesty).
- `Reservations::Relocate`: `PUT /reservations-v3/{id}/relocate` (change the listing).
- `Payments::Index`: `GET /payments` — a reservation's payments with `totalPaid`, `balanceDue` and
  `isFullyPaid`.
- `Payments::Record`: `POST /payments/record` — record an offline payment (`shouldBePaidAt`, method
  `RECORDED_CASH` unless given).

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

[Unreleased]: https://github.com/guestitab/guesty-client/compare/v0.2.0...staging
[0.2.0]: https://github.com/guestitab/guesty-client/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/guestitab/guesty-client/releases/tag/v0.1.0
