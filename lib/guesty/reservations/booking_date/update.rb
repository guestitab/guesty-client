module Guesty
  module Reservations
    module BookingDate
      class Update
        include Guesty::Operation

        # @rbs (reservation_id: ::String, booking_date: ::Time) -> Dry::Monads::Result[bool]
        def call(reservation_id:, booking_date:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! booking_date: :required if booking_date.blank?

          request(:put, "reservations-v3/#{reservation_id}/booking-date", { bookingDate: booking_date.utc.iso8601(3) })

          Success(true)
        end
      end
    end
  end
end
