module Guesty
  module Reservations
    # Reads one reservation from reservations-v3 (the legacy /reservations/{id}
    # retires on 2027-03-01). The payload carries stay segments (stay[] with
    # unitId/unitTypeId, localized dates, eta/etd and the guests breakdown), an
    # embedded money object and channelMetadata; the guest comes by reference
    # (bookerId) through Guests::Profiles::Show.
    class Show
      include Guesty::Operation

      # @rbs (reservation_id: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(reservation_id:)
        argument! reservation_id: :required if reservation_id.blank?

        response = Guesty.do_request(:get, 'reservations-v3', { reservationIds: [reservation_id] })
        return response unless response.success?

        reservation = response.value!.body.find { |row| row[:_id] == reservation_id }
        error! "Reservation #{reservation_id} not found on Guesty", fatal: true unless reservation

        Success(reservation)
      end
    end
  end
end
