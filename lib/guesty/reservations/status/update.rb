module Guesty
  module Reservations
    module Status
      class Update
        include Guesty::Operation

        # @rbs (reservation_id: ::String, attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[bool]
        def call(reservation_id:, attributes:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! attributes: :required if attributes.blank?

          response = Guesty.do_request :put, "reservations-v3/#{reservation_id}/status", attributes

          raise response.failure unless response.success?

          Success(true)
        end
      end
    end
  end
end
