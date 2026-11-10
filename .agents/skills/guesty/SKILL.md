---
name: guesty
description: "Guesty API behaviour and Core's Guesty integration. Load before changing lib/providers/channel_managers/guesty or app/operations/channel_managers/guesty, Guesty webhooks or imports, guest messages and SMS, booking requests and inquiries, or custom fields, and before a live Guesty call or a Guesty cassette."
---

# Guesty

Guesty is the channel manager: listings, reservations, guest threads and reviews come from it, and Core writes
reservations, custom fields and replies back.

## Where Core meets Guesty

- `lib/providers/channel_managers/guesty/`: one class per endpoint behind `Guesty.do_request`. Provider classes
  below are named relative to `Providers::ChannelManagers::Guesty`; app names carry a leading `::`.
  `app/operations/channel_managers/guesty/` maps Guesty data onto the models (reservation import and export,
  conversation import, webhook handlers); `app/services/importers/guesty/` and `app/jobs/importers/guesty/` poll.
- Webhooks: `Webhooks::GuestyController` checks the Svix signature (`Webhooks::Signatures::Verify`), then
  `ChannelManagers::Guesty::Webhooks::Receive` hands the delivery to the handler for its event
  (`ChannelManagers::Guesty::Webhooks::BY_EVENT`). Find payloads in SigNoz logs with
  `controller = Webhooks::GuestyController`, under `params`; the trace's `http.request.params` truncates large payloads.
  Handlers only push ids to Redis queues
  (`Queues::Reservations::Import`, `Queues::HomeAvailabilities::Import`, `Queues::Conversations::Import`,
  `Queues::Resolutions::Import`) that cron workers drain (`config/production_schedule.yml`: conversations every minute,
  reservations every 3 minutes, resolutions and availabilities every 5 and 10 minutes); a reservation event also
  rebuilds the home's availability. A guest-folio event also refreshes the reservation.
- `guesty.webhook_key` in credentials is the account's Svix signing secret; while it is blank every delivery gets 401.
  `bin/rails 'providers:channel_managers:guesty:sync_webhooks[<url>,...]'` subscribes the URLs to the events in
  `BY_EVENT` (production with no argument registers the Core and staging endpoints). A new handler receives nothing
  until that task has run in production; it writes to the live account, so confirm first.
- `ChannelManagers::Guesty::Reservations::Export` returns early on staging, and `::Reservations::Groups::Cancel`
  skips its Guesty cancels there. Request answers, owner-stay changes, manual and group bookings and grant syncs still
  write to the live account from staging.

## Calls and tokens

- User-triggered writes run inside `Guesty.with_priority(:high)` (its own token slots and rate limits); imports stay
  on the default priority. A non-idempotent `POST` passes `retries: 0`.
- After a failed write, `Guesty.unapplied?(error)` means it did not land: undo the local claim, as
  `::Reservations::Requests::Accept` does. `Guesty.delivery_unknown?(error)` means it may have landed: record that and
  reconcile, as `::Reservations::OwnerStays::Create#export_later` does.
- Guesty mints 5 access tokens per client id per 24 hours and answers 429 to everything after. `AccessTokens::Upsert`
  keeps the token encrypted in `guesty_access_tokens` and in `Rails.cache`. Rows encrypted under other keys (a
  database restored from a production dump, staging after a refresh from production) cannot be read: every call
  then mints a token and fails to save it. Delete the rows in that database (`Guesty::AccessToken.delete_all`); each
  slot then costs one token.
- The development credentials reach the live production account: a console call reads and writes real bookings and
  threads. Probes are GETs. To probe without touching the token rows, send the form `Upsert` sends to
  `Upsert::OAUTH_ENDPOINT` through `Guesty.connection(url:, skip_auth: true)` with `token_slots(:default).first`, keep
  the token in memory, and send GETs on `Guesty.connection(skip_auth: true)` with your own `Authorization` header.
- For an endpoint the docs do not describe, take the response shape from one live GET before writing the normalizer
  or recording a cassette.
- API docs read as Markdown at `<doc url>.md`; the index is `https://open-api-docs.guesty.com/llms.txt`. Help
  centre articles answer 403 as HTML; read `https://help.guesty.com/api/v2/help_center/en-gb/articles/<id>.json`.

## Reservations

- The legacy `/reservations` endpoints retire on 2027-03-01, along with the legacy reservation webhooks and the
  legacy guest payment resources (migration guide: https://open-api-docs.guesty.com/docs/reservation-migration,
  read it with `.md` appended). Retrieval: `Reservations::Search` (`GET reservations-v3/search`; filters
  `status`, `confirmation_code`, `listing_id`, `source` or a Range on `check_in`/`check_out`/`created_at`; no
  lastUpdatedAt filter, no `fields:` selection, items keyed by `reservationId`), `Reservations::Show` and
  `Reservations::Index` (`GET reservations-v3` by id, up to 10 ids; stay segments, embedded money and
  channelMetadata, guest only by `bookerId`). Writes are one endpoint per operation: `Status::Update`,
  `Status::Cancel`, `Dates::Update`, `Guests::Update`, `ConfirmationCode::Update`, `Source::Update`,
  `BookingDate::Update`, `Relocate`, `CustomFields::Update`. Payments: `Payments::Index` (`GET /payments`) and
  `Payments::Record` (`POST /payments/record`; 503 PAYMENT_RESERVATION_NOT_READY right after creation is
  transient) — `Reservations::Payments::Create` composes them. `AccommodationFare::Update` reads the fare from
  `GuestFolio::InvoiceItems::Index` and posts `price-adjustments/manual-total-amount` (both unchanged).
- Status changes go through `Reservations::Status::Update` or `Status::Cancel` (`canceledBy` GUEST, OWNER or
  TEAM_MEMBER); a canceled reservation refuses a full `Update` with 400. `::Reservations::Groups::Cancel`,
  `::Reservations::Groups::Book` and `::Reservations::Manual::Create` still cancel through the legacy
  `Reservations::Update`.
- A request to book is an Airbnb stay in Guesty status `reserved`; the import sets `request_due_at` from
  `Reservations::REQUEST_WINDOW`. Core maps `reserved` to `awaiting_payment` and exports its own unpaid direct
  bookings as `reserved`, so the status alone is no request.
- `reservations-v3/{id}/approve` and `/decline` accept only `reserved`, run asynchronously and answer a repeat with
  400 DUPLICATE. Decline needs a `reason` (Airbnb answers 422 without one); Guesty documents only
  `dates_not_available`, Core sends `::Reservations::REQUEST_DECLINE_REASONS`.
- An inquiry cannot be declined through Guesty (declining it in Airbnb leaves it `inquiry` in Guesty); the answer is a
  message or `pre-approve` (Airbnb only, asynchronous). Alteration requests and special offers have no API.
- A write Guesty rejects can still re-render the money and fire `reservation.updated`, so a loop retrying a rejected
  write becomes a webhook storm through import and availability. Retry state clears on
  `ApiError#permanent_rejection?`, as in `Exporters::Guesty::Ago::ReservationsJob`.
- Custom field ids live in `::Reservations::GUESTY_CUSTOM_FIELDS`; the non-production ids are not in the account the
  development credentials reach. To look a field up: `GET accounts/me?fields=_id`, then
  `GET accounts/{id}/custom-fields` (one flat array; `key` holds the label and `displayName` the snake name).

## Conversations and messages

- Every reservation has a Guesty conversation (`conversationId`, stored as `provider_conversation_id`), and one
  conversation can list several stays (`Conversations::Show`). The API creates no conversation and sends to no
  arbitrary number.
- `reservation.messageReceived` and `reservation.messageSent` carry the thread only as `conversation._id`.
  `messageSent` also fires for Core's own sends, and delivery takes from seconds to 30 minutes, so the
  `Importers::Guesty::ConversationsJob` poll runs beside the webhooks.
- Reservation log posts, including Airbnb alteration requests, import as system lines. `guest-folio.updated` imports
  closed Airbnb Resolution Center items through `GuestFolio::InvoiceItems::Index`: negative amounts are refunds and
  positive amounts are guest charges. Airbnb sends only closed resolutions, usually once a day.
- A guest send goes `::Conversations::Messages::Send` (automated replies and approved drafts) or
  `::Conversations::Messages::Reply` (staff) → `::Conversations::Messages::Deliver` → `GuestConversation#post` → the
  provider `Conversations::Messages::Reply`. Module type `platform` lets Guesty pick the booking channel or email and
  echo the one it used.
- SMS: Guesty sends it from a shared number per guest country code. The API sends the whole body
  (`::Conversations::MAX_BODY_LENGTH` is the cap); a guest with no phone in Guesty gets a 500
  `HTTP_UPSTREAM_REQUEST_ERROR` and no post; `module.to` must be an array. A guest's SMS reply reaches the thread only
  when Guesty holds that phone, and its images are dropped.
- Posts carry attachment storage keys; `Conversations::Attachments::Index` trades them for signed URLs that expire
  after about an hour.
- Guesty automations already email and text guests on a new booking and on a cancellation. Core's only guest email
  is `Guests::ReservationsMailer#cancelled`; check the Guesty automations before adding another.

## Listings, reviews, saved replies

- `GET reviews`: `startDate` and `endDate` filter on the review's `updatedAt`, newest update first. Airbnb raw reviews
  carry `category_ratings[].review_category_tags`; Booking.com and Vrbo carry none.
- `GET listings/tags` returns tag names only; map tags to listings through the `tags` field of `GET listings`.
  `active` is a filter, so all listings take two passes. Core imports only `SINGLE` and `MTL_CHILD` listings.
- `GET saved-replies` (`{ count, limit, skip, results }`): `language` reads `en` on every row whatever the text, and
  the placeholders differ from `::Conversations::SavedReplies::Context::VARIABLES` (`{{guest_first}}` is
  `guest_first_name`).
- No provider class reads account custom fields, listing tags or saved replies; a one-off read calls
  `Guesty.do_request`.

## Pull one live booking into a scratch database

Runs branch code on a real booking and its thread with no provider writes and one token.

1. Copy the development database:
   `psql -d postgres -c "CREATE DATABASE <copy> TEMPLATE guestit_core_development STRATEGY FILE_COPY"`. It fails
   while anything is connected to the source; check `pg_stat_activity`.
2. Migrate only the copy:
   `DATABASE_URL=postgres:///<copy> SCHEMA=<scratch>/schema.rb bin/rails db:migrate:primary`. `SCHEMA` sends the dump
   elsewhere, so `db/schema.rb` stays as it is.
3. Run a script with `DATABASE_URL` set that first does `Sidekiq.testing!(:fake)` and `Searchkick.disable_callbacks`,
   and aborts unless `current_database` is the copy. Tally the faked jobs at the end,
   then `Sidekiq::Queues.clear_all`.
4. Pin `Guesty.pick_slot` to `token_slots(:default).first` and delete that slot's `Guesty::AccessToken` row in the
   copy: `Upsert` mints exactly one token and caches it.
5. Find the Guesty id with `Reservations::Search` (`fields:` and `attributes: { confirmation_code: }`), import it with
   `Importers::Guesty::Reservations::Single.new(external_id:).call`, then the thread with
   `ChannelManagers::Guesty::Conversations::Import.new.call(provider_conversation_id:, arm_first_read: true)`, the
   webhook path.
6. Print ids, statuses and counts, never guest names. `dropdb <copy>` once the result has been looked at.
