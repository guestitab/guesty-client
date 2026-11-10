module Guesty
  module Reservations
    # Unknown ids are silently absent from the response.
    class Index
      include Guesty::Operation

      TAKE = 10 #: ::Integer # Max allowed by the Guesty API

      # @rbs (reservation_ids: ::Array[::String]) -> Dry::Monads::Result[::Array[::Hash[::Symbol, untyped]]]
      def call(reservation_ids:)
        argument! reservation_ids: :required if reservation_ids.blank?
        argument! reservation_ids: :invalid if reservation_ids.size > TAKE

        Success(request(:get, 'reservations-v3', { reservationIds: reservation_ids }))
      end
    end
  end
end
