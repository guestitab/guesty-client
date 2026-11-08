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
        if (token = store.read(Guesty.current_slot[:key]))
          return Success(token)
        end

        response = request_access_token
        raise ApiError, response unless Guesty.successful_response?(response)

        Success(save_token(response))
      end

      private

      def store
        Guesty.config.token_store
      end

      def client_id
        Guesty.current_slot[:client_id]
      end

      def client_secret
        Guesty.current_slot[:secret]
      end

      def request_access_token
        Guesty.connection(url: OAUTH_ENDPOINT, skip_auth: true).post do |req|
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          req.body = {
            grant_type: 'client_credentials',
            scope: 'open-api',
            client_secret:,
            client_id:
          }
        end
      end

      def save_token(response)
        store.save(
          slot_key: Guesty.current_slot[:key],
          access_token: response.body[:access_token],
          expires_at: response.body[:expires_in].seconds.from_now
        )
      end
    end
  end
end
