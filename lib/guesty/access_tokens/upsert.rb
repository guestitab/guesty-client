module Guesty
  module AccessTokens
    class Upsert
      include Guesty::Operation

      OAUTH_ENDPOINT = 'https://open-api.guesty.com/oauth2/token'.freeze #: ::String
      MINT_INTERVAL = 10.minutes #: untyped
      REFRESH_WINDOW = 30.minutes #: untyped

      # @rbs () -> Dry::Monads::Result[untyped]
      def call
        slot = Guesty.current_slot
        token = store.read(slot[:key])
        return Success(token) if token && token.expires_at > REFRESH_WINDOW.from_now

        Success(mint_or_fallback(slot, token))
      end

      private

      def store
        Guesty.config.token_store
      end

      # A token must never be discarded: Guesty mints only 5 access tokens per client id per day, counts every
      # token request (502 answers included) and answers 429 to everything after, until 00:00 UTC. A failed or
      # throttled mint keeps the stored token, or borrows another slot's, and never saves the borrowed one here.
      # @rbs (Guesty::slot slot, untyped token) -> untyped
      def mint_or_fallback(slot, token)
        mint(slot)
      rescue Guesty::Error, Faraday::Error => e
        token || borrowed_token || raise(e)
      end

      # @rbs () -> untyped
      def borrowed_token
        slots = (Guesty.config.credentials.keys - [:webhook_key]).flat_map { |priority| Guesty.token_slots(priority) }

        slots.lazy.filter_map { |slot| store.read(slot[:key]) }.first
      end

      # @rbs (Guesty::slot slot) -> untyped
      def mint(slot)
        Guesty.config.rate_limiter.throttle!(key: :"guesty_token_mint_#{slot[:key]}", threshold: 1, interval: MINT_INTERVAL)

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
