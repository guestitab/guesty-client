require 'guesty'
require 'vcr'
require 'webmock/rspec'
require 'active_support/testing/time_helpers'

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |file| require file }

# Core's app time zone, so Time.zone.local in ported specs builds the same
# instants the cassettes were recorded with.
Time.zone = 'Europe/Stockholm'

# Fake real-looking credentials, filtered into the cassettes' placeholders
# (ported from core's spec/support/vcr.rb, where the real account secrets
# were scrubbed to [GUESTY_<PRIORITY>_<INDEX>_CLIENT_ID] etc.).
GUESTY_TEST_CREDENTIALS = {
  default: [
    { client_id: 'test-default-0-client-id', secret: 'test-default-0-client-secret' },
    { client_id: 'test-default-1-client-id', secret: 'test-default-1-client-secret' }
  ],
  high: [{ client_id: 'test-high-0-client-id', secret: 'test-high-0-client-secret' }],
  webhook_key: 'whsec_dGVzdA=='
}.freeze

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path('fixtures/cassettes', __dir__)
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    allow_unused_http_interactions: false,
    match_requests_on: %i[method uri body]
  }

  # VCR replays buffered bodies, so recorded chunked-transfer framing no longer applies.
  config.before_playback do |interaction|
    interaction.response.headers.delete_if { |header,| header.casecmp?('Transfer-Encoding') }
  end

  guesty_uri = %r{\Ahttps://open-api\.guesty\.com/}
  filter_credential = lambda do |placeholder, &credential|
    config.filter_sensitive_data(placeholder) do |interaction|
      credential.call if interaction.request.uri.match?(guesty_uri)
    end
  end

  %i[default high].each do |priority|
    GUESTY_TEST_CREDENTIALS[priority].each_with_index do |guesty_credentials, index|
      placeholder = "GUESTY_#{priority.to_s.upcase}_#{index}"

      filter_credential.call("[#{placeholder}_CLIENT_ID]") { guesty_credentials[:client_id] }
      filter_credential.call("[#{placeholder}_CLIENT_SECRET]") { guesty_credentials[:secret] }
    end
  end
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.include ActiveSupport::Testing::TimeHelpers
  config.include Dry::Monads[:result]

  config.before do
    Guesty.configure do |guesty|
      guesty.credentials = GUESTY_TEST_CREDENTIALS
      guesty.token_store = Guesty::MemoryTokenStore.new
      guesty.rate_limiter = Guesty::MemoryRateLimiter.new
      guesty.custom_fields = {
        blacklisted: '6821ff700090ff004bcc8175',
        grants_created: '68303d6eee7db8001b2b9da7',
        grants_partial: '6a3b1269be29410014f4fb7d'
      }
      guesty.default_currency = 'SEK'
      guesty.slot_picker = ->(slots, _priority) { slots.first }

      Guesty.token_slots.each do |slot|
        guesty.token_store.save(slot_key: slot[:key], access_token: 'test-access-token', expires_at: Time.now + 3600)
      end
    end
  end
end
