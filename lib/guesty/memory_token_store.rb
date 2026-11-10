module Guesty
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
  end
end
