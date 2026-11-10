module Guesty
  module Reservations
    module CustomFields
      class Update
        include Guesty::Operation

        # @rbs (reservation_id: ::String, custom_fields: ::Array[::Hash[::Symbol, untyped]]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
        def call(reservation_id:, custom_fields:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! custom_fields: :required if custom_fields.blank?

          Success(request(:put, "reservations-v3/#{reservation_id}/custom-fields", { customFields: custom_fields }))
        end
      end
    end
  end
end
