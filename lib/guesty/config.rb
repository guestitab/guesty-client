module Guesty
  # Injected by the host app (see the Guesty.configure initializer): the API
  # credentials per priority lane, the webhook signing key, a token store, a
  # rate limiter and a slot picker. Keeping these out of the gem is what makes
  # it host-agnostic.
  #
  # credentials maps each priority to its client credentials, plus webhook_key:
  #
  #   {
  #     default: [{ client_id: '...', secret: '...' }, ...],
  #     high:    [{ client_id: '...', secret: '...' }],
  #     webhook_key: 'whsec_...'
  #   }
  class Config
    attr_accessor :credentials, :token_store, :rate_limiter, :slot_picker, :base_url, :sync_guest_and_reservation_changes, :custom_fields,
                  :default_currency

    def initialize
      @base_url = BASE_URL
      @credentials = {}
      @custom_fields = {}
      @default_currency = nil
      @token_store = MemoryTokenStore.new
      @rate_limiter = MemoryRateLimiter.new
      @slot_picker = ->(slots, _priority) { slots.first }
      @sync_guest_and_reservation_changes = false
    end
  end
end
