module Guesty
  module Reservations
    module Stays
      class Update
        include Guesty::Operation

        # @rbs (reservation_id: ::String, stay: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[bool]
        def call(reservation_id:, stay:)
          response = Guesty.do_request(
            :put,
            "reservations/#{reservation_id}",
            stay_attributes(stay)
          )

          raise response.failure if response.failure?

          Success(true)
        end

        private

        # @rbs (::Hash[::Symbol, untyped] stay) -> ::Hash[::Symbol, untyped]
        def stay_attributes(stay)
          {
            checkInDateLocalized: stay.fetch(:start_date).iso8601,
            checkOutDateLocalized: stay.fetch(:end_date).iso8601,
            plannedArrival: stay.fetch(:check_in).strftime('%H:%M'),
            plannedDeparture: stay.fetch(:check_out).strftime('%H:%M'),
            guestsCount: stay.fetch(:num_guests),
            numberOfGuests: {
              numberOfAdults: stay.fetch(:adults),
              numberOfChildren: stay.fetch(:children)
            },
            ignoreCalendar: stay.fetch(:ignore_calendar),
            ignoreTerms: true,
            listingId: stay.fetch(:listing_external_id)
          }
        end
      end
    end
  end
end
