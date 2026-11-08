module Guesty
  # The default token store: keeps one token per credential slot in memory for
  # the life of the process. Guesty mints only 5 tokens per client id per 24
  # hours, so a multi-process host must inject a shared, persistent store, such
  # as a database table behind a cache.
  class MemoryTokenStore
    Token = Struct.new(:access_token, :expires_at, keyword_init: true) do
      def expired?
        expires_at.nil? || expires_at < Time.now
      end
    end

    def initialize
      @tokens = {}
    end

    # @rbs (::String slot_key) -> Token?
    def read(slot_key)
      token = @tokens[slot_key]

      token if token && !token.expired?
    end

    # @rbs (slot_key: ::String, access_token: ::String, expires_at: ::Time) -> Token
    def save(slot_key:, access_token:, expires_at:)
      @tokens[slot_key] = Token.new(access_token:, expires_at:)
    end

    def clear
      @tokens = {}
    end
  end
end
