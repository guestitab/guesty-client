---
name: write-provider
description: "Add or change an integration under lib/providers: an HTTP vendor call, a vendor module with its Faraday connection and ApiError, or an infrastructure provider such as the Kubernetes cron job sync, with VCR, WebMock or concurrency specs."
---

# Write provider

## Choose the shape

- HTTP vendor: one class per endpoint call, `Providers::<Domain>::<Vendor>::<Resource>::<Action>` (Fubuki has no
  domain: `Providers::Fubuki::<Resource>::<Action>`). The vendor module owns the Faraday connection or SDK client,
  retries, auth and error wrapping (`do_request` in Guesty and Airdna, `connection` elsewhere, `request` for
  Stargate); an endpoint class never builds its own client. Credential and priority helpers
  (`Guesty.with_priority(:high) { ... }`) live there too.
- Infrastructure: `Providers::Kubernetes::CronJobs::Sync` and `SyncOnce` wrap the in-cluster Kubernetes API and the
  manifest file. The once variant fingerprints its inputs (environment included when the target differs by
  environment), takes a lock, stores the synced marker only after success, and returns successful skip payloads for
  the already-synced and already-running cases.

Create a vendor module and `ApiError` only when the vendor does not exist yet.

## Vendors

- Guesty: load the `guesty` skill for its API behaviour and Core's Guesty integration facts.
- Fubuki: load the `fubuki` skill.
- Parakey (`Providers::Stargate::Parakey`): the endpoint reference is the apiDoc bundle
  `https://api-doc.parakey.co/assets/main.bundle.js` (search `url:"/event-logs"`). Filterable parameters take
  `field=a,b`, `field[gte]=`, `field[ne]=` and `orderBy=<field>:asc|desc`. Poll `GET /event-logs`
  (`Accept-Version: 2.0`) by `createdAt`, the time a log reached Parakey; `timestamp` is the unlock, which offline
  phones upload days late. A webhook delivery gets six attempts over about five hours and is then dropped, and Parakey
  switches a webhook off after 10 failures in five days or 100 in a day; recover dropped events from `/event-logs`.
- Operto: a new or changed API call goes into the `operto` gem (`guestitab/operto-client`); Core's task pipeline is
  `app/operations/workspaces/operto`. Task writes carry property, rule, name, description and dates, and staff goes
  through `Operto::StaffTasks::Create` and `Destroy`; the gem sends no completion or active flag, so Core never closes
  an Operto task. Only production credentials authenticate: every live Operto call reads or writes the production
  account.

## Change an existing contract

Read the caller, endpoint class, vendor helper and cassette together. Identify the wire request and the normalized
value the caller consumes. Compare method, path, query, body and response envelope before changing a default or
adding a fallback. An unmatched VCR interaction is evidence of request drift until that comparison explains it.
When shared parsing or retry behaviour changes, exercise a representative endpoint through the real helper as
well as its focused spec.

## HTTP call

```ruby
module Providers
  module ChannelManagers
    module Guesty
      module Reservations
        class Decline < Operations::Base
          schema do
            required(:reservation_id).filled
            required(:reason).filled
            required(:message).filled
          end

          # @rbs (reservation_id: ::String, reason: ::String, message: ::String) -> Dry::Monads::Result[bool]
          def call(reservation_id:, reason:, message:)
            body = {
              reason:,
              messageToGuest: message
            }
            response = Guesty.do_request(:post, "reservations-v3/#{reservation_id}/decline", body, retries: 0)
            return response unless response.success?

            Success(true)
          end

        end
      end
    end
  end
end
```

- Read `docs/operation-validation.md` before changing input checks. RBS owns input types; native `schema`
  and `rule` declarations check raw kwargs before `call`. Helpers return values or raise; only `call` builds a Result.
  Response checks stay after the request.
- Normalize the response inside the provider (keys, dates, calendar partitioning, review extraction) so app code reads
  one shape.
- When callers branch on an HTTP status or vendor code, expose it as a typed member of the `ApiError` rather than
  through the message text.
- A timeout after a non-idempotent `POST` is unknown delivery: the caller records an explicit state and reconciles by
  exact provider identity before retrying; the provider never reports it as sent or unsent.

## Spec

```ruby
RSpec.describe Providers::ChannelManagers::Guesty::Reservations::Decline do
  include_context 'operations'
  include_context 'with guesty access token'

  let(:args) do
    {
      reservation_id:,
      reason:,
      message: guest_message
    }
  end

  let(:reservation_id) { '6a06db716203cc0e830c0a0b' }
  let(:reason) { Reservations::REQUEST_DECLINE_REASONS[:dates_not_available] }
  let(:guest_message) { 'Sorry, the home is not free on those dates.' }
  let(:endpoint) { "https://open-api.guesty.com/v1/reservations-v3/#{reservation_id}/decline" }

  context 'with valid arguments' do
    before do
      stub_request(:post, endpoint)
        .to_return(status: 201, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it_behaves_like 'successful call', value: true

    context 'when Guesty takes the answer' do
      before { result }

      it 'sends the reason and the message to the guest' do
        expect(WebMock).to have_requested(:post, endpoint).with(
          body: {
            reason:,
            messageToGuest: guest_message
          }
        ).once
      end
    end

    context 'when the request is no longer open' do
      let(:message) { 'Invalid reservation status for approve/decline' }
      let(:error_body) do
        {
          error: {
            message: 'Invalid status',
            data: message
          }
        }
      end

      before do
        stub_request(:post, endpoint)
          .to_return(status: 400, body: error_body.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it_behaves_like 'failed call', failure_class: Providers::ChannelManagers::Guesty::ApiError
    end
  end

  context 'with invalid arguments' do
    context 'when the reason is blank' do
      let(:reason) { '' }
      let(:message) { I18n.t('dry_validation.errors.providers.channel_managers.guesty.reservations.decline.rules.reason.filled?') }

      it_behaves_like 'failed call', failure_class: Operations::Errors::ArgumentError
    end
  end
end
```

- Specs cover blank, nested, range and cross-field refusals and absence of requests on failure. RBS owns input
  types. Transport errors and retries are specced once per vendor helper.
- Auth contexts: `'with guesty access token'`, `'with stargate access tokens'`, `'with coral esim access token'`.
- Stubs mirror the exact transport: status, body presence and content type. A bodyless endpoint is stubbed with an
  empty body. A live cassette sits at `vcr: { cassette_name: 'lib/<domain>/<vendor>/<resource>/<action>' }`.
- Infrastructure providers cover idempotency, a changed fingerprint, a failed underlying sync, retry after failure,
  lock contention and a reused instance. A race runs the competing call in a `Thread` held at a `Queue` barrier in the
  exact window (a second database connection under `:truncation` when the lock is a row lock) and joins it in
  `after`.

## Verify

```bash
bundle exec rubocop -A --force-exclusion <provider_files> <spec_path>
bundle exec rspec <spec_path>
bundle exec core-typecheck
bin/steep-fast
```

Cassette recording makes live provider calls and follows the authorization rule in `AGENTS.md`. An unmatched
request does not authorize re-recording. After authorized recording, inspect the request and response for secrets,
keep only the interactions the spec uses and remove a temporary `record: :all` override before committing.
