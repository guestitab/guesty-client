# Changelog

## [Unreleased]

### Added

- Initial extraction from Guestit core (`Providers::ChannelManagers::Guesty` → `Guesty`),
  verified by porting core's provider specs 1:1 with their recorded VCR cassettes.
- Wire API on the `Guesty` module: `connection`, `do_request` (glitch retries), `with_priority`
  lanes, credential slots (`token_slots`, `pick_slot`), `retryable_read?` / `unapplied?` /
  `delivery_unknown?` error classification, `webhook_key`.
- `Guesty.configure` injecting credentials, token store, rate limiter, slot picker,
  custom field ids, default currency and the sync flag — no Rails dependency.
- `sig/guesty.rbs` declaring the public API, loaded by host apps through `rbs collection`.
- Operations (`include Guesty::Operation`, monadic Results, `argument!` / `error!` refusals):
  - `AccessTokens::Upsert` — OAuth client-credentials mint, one stored token per slot.
  - Reservations: `Search`, `Show`, `Create`, `Update`, `Recover`, `Approve`, `Decline`,
    `PreApprove`, `Status::Update`, `Status::Cancel`, `Dates::Update`, `Stays::Update`,
    `Flags::Update`, `AccommodationFare::Update`, `CustomFields::Update`, `Payments::Create`.
  - Conversations: `Index`, `Show`, `Search`, `Posts::Index`, `Posts::Since`, `Messages::Reply`,
    `Attachments::Index`; `Conversations.channel` and `Reservations.from_conversation` helpers.
  - Reviews: `Reviews::Respond` and `Reservations::Reviews::Index` with per-channel extractors
    (Airbnb, Booking.com, Vrbo).
  - Guests: `Profiles::Create`, `Profiles::Show`, `Profiles::Update` (tag merge via read-back).
  - Homes: `Search`, `Calendars::Show` (block classification, checkout-day rule).
  - `GuestFolio::InvoiceItems::Index` (Airbnb Resolution Center items).
  - Webhooks: `Index`, `Create`, `Update`, `Sync`, `Signatures::Verify` (Svix HMAC).
  - Views: `Create`, `Update`.

### Boundary

- Core keeps `Reservations::Payloads::Import` and `Reservations::Payloads::Render`: they map
  Guesty payloads onto domain vocabulary (statuses, channels, guest types, currencies), which is
  host knowledge, not wire knowledge. They reference the gem's `Guesty::Reservations::CLOSED_STATUSES`
  and `Guesty::Guests::OTA_LINK_TYPES` constants.
- Core keeps `Guesty::AccessToken` (the encrypted AR model) behind the injected token store.
