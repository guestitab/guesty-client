module Guesty
  module Reservations
    module BookingDate
      # Sets the real-world booking date (bookingDate) of a reservation; Guesty
      # keeps createdAt as the canonical entry time. Sent in UTC.
      class Update
        include Guesty::Operation

        # @rbs (reservation_id: ::String, booking_date: ::Time) -> Dry::Monads::Result[bool]
        def call(reservation_id:, booking_date:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! booking_date: :required if booking_date.blank?

          response = Guesty.do_request(
            :put,
            "reservations-v3/#{reservation_id}/booking-date",
            { bookingDate: booking_date.utc.iso8601(3) }
          )

          raise response.failure if response.failure?

          Success(true)
        end
      end
    end
  end
end
