module Guesty
  module Payments
    class Index
      include Guesty::Operation

      # @rbs (reservation_id: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(reservation_id:)
        argument! reservation_id: :required if reservation_id.blank?

        Success(request(:get, 'payments', { reservationId: reservation_id }))
      end
    end
  end
end
