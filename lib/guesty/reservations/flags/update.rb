module Guesty
  module Reservations
    module Flags
      # Sets account custom fields on a reservation. The field ids are
      # account-specific, so the host injects them (Guesty.config.custom_fields,
      # keyed by flag name: blacklisted, grants_created, grants_partial).
      class Update
        include Guesty::Operation

        # @rbs (reservation_id: ::String, flags: ::Hash[::Symbol, bool]) -> Dry::Monads::Result[bool]
        def call(reservation_id:, flags:)
          custom_fields = flags.map { |name, value| { fieldId: field_ids.fetch(name), value: value.to_s } }
          body = { customFields: custom_fields }
          response = Guesty.do_request(
            :put,
            "reservations-v3/#{reservation_id}/custom-fields",
            body
          )

          raise response.failure if response.failure?

          Success(true)
        end

        private

        def field_ids
          Guesty.config.custom_fields
        end
      end
    end
  end
end
