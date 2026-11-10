module Guesty
  class Config
    attr_accessor :credentials, :token_store, :rate_limiter, :slot_picker, :base_url, :default_currency

    def initialize
      @base_url = BASE_URL
      @credentials = {}
      @default_currency = nil
      @token_store = MemoryTokenStore.new
      @rate_limiter = MemoryRateLimiter.new
      @slot_picker = ->(slots, _priority) { slots.first }
    end
  end
end
