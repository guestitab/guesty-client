module Guesty
  module Reservations
    # Reads one reservation through Index (the legacy /reservations/{id}
    # retires on 2027-03-01). The payload carries stay segments (stay[] with
    # unitId/unitTypeId, localized dates, eta/etd and the guests breakdown) and
    # channelMetadata. Nothing is embedded: the guest comes by reference
    # (bookerId) through Guests::Profiles::Show, the payout and payments through
    # Payments::Index, and the pricing through GuestFolio.
    class Show
      include Guesty::Operation

      # @rbs (reservation_id: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(reservation_id:)
        argument! reservation_id: :required if reservation_id.blank?

        reservation = Index.new.call!(reservation_ids: [reservation_id]).value!.find { |row| row[:_id] == reservation_id }
        error! "Reservation #{reservation_id} not found on Guesty", fatal: true unless reservation

        Success(reservation)
      end
    end
  end
end
