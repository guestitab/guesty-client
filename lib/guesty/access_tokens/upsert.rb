module Guesty
  module AccessTokens
    # Ensures a live access token for the current credential slot: reuse the
    # stored one, else mint one. Persistence, caching and expiry policy live in
    # the injected token store (Guesty.config.token_store).
    #
    # Guesty mints only 5 access tokens per client id within 24 hours and
    # answers 429 to everything after, so a token must never be discarded.
    class Upsert
      include Guesty::Operation

      OAUTH_ENDPOINT = 'https://open-api.guesty.com/oauth2/token'.freeze #: ::String

      # @rbs () -> Dry::Monads::Result[untyped]
      def call
        slot = Guesty.current_slot

        Success(store.read(slot[:key]) || mint(slot))
      end

      private

      def store
        Guesty.config.token_store
      end

      # @rbs (Guesty::slot slot) -> untyped
      def mint(slot)
        response = Guesty.connection(url: OAUTH_ENDPOINT, skip_auth: true).post do |req|
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          req.body = { grant_type: 'client_credentials', scope: 'open-api', client_secret: slot[:secret], client_id: slot[:client_id] }
        end
        raise ApiError, response unless Guesty.successful_response?(response)

        store.save(slot_key: slot[:key], access_token: response.body[:access_token], expires_at: response.body[:expires_in].seconds.from_now)
      end
    end
  end
end
