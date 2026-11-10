require 'base64'
require 'openssl'

module Guesty
  module Webhooks
    # Svix signs "<svix-id>.<svix-timestamp>.<raw body>" with the base64 after the whsec_ prefix;
    # svix-signature lists space-separated "version,base64-HMAC-SHA256" entries, one per active key.
    module Signatures
      class Verify
        include Guesty::Operation

        SECRET_PREFIX = 'whsec_'.freeze
        SIGNATURE_VERSION = 'v1'.freeze
        TOLERANCE = 5.minutes.freeze #: ActiveSupport::Duration

        # @rbs (payload: ::String, headers: untyped) -> Dry::Monads::Result[bool]
        def call(payload:, headers:)
          argument! payload: :required if payload.nil?
          argument! headers: :required if headers.nil?

          id = headers['svix-id']
          timestamp = headers['svix-timestamp']
          signatures = headers['svix-signature']

          error! 'Missing Svix headers' if id.blank? || timestamp.blank? || signatures.blank?

          verify_timestamp!(timestamp)
          error! 'No matching Svix signature' unless signed?(signatures, sign(id, timestamp, payload))

          Success(true)
        end

        private

        # Refuses replays of a captured delivery.
        # @rbs (untyped header) -> void
        def verify_timestamp!(header)
          timestamp = Integer(header, exception: false)
          error! 'Invalid Svix timestamp' if timestamp.nil?
          error! 'Svix timestamp is outside the tolerance' unless timestamp.between?(TOLERANCE.ago.to_i, TOLERANCE.from_now.to_i)
        end

        # @rbs (::String id, ::String timestamp, ::String payload) -> ::String
        def sign(id, timestamp, payload)
          Base64.strict_encode64(
            OpenSSL::HMAC.digest(
              'sha256',
              secret,
              "#{id}.#{timestamp}.#{payload}"
            )
          )
        end

        # @rbs (::String header, ::String expected) -> bool
        def signed?(header, expected)
          header.split.any? do |versioned_signature|
            version, signature = versioned_signature.split(',', 2)

            version == SIGNATURE_VERSION && signature && ActiveSupport::SecurityUtils.secure_compare(signature, expected)
          end
        end

        # @rbs () -> ::String
        def secret
          decoded = Base64.decode64(Guesty.webhook_key.to_s.delete_prefix(SECRET_PREFIX))
          error! 'Guesty webhook signing key is not configured' if decoded.empty?

          decoded
        end
      end
    end
  end
end
