module Guesty
  module Reservations
    module Dates
      class Update
        include Guesty::Operation

        # @rbs (reservation_id: ::String, attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[bool]
        def call(reservation_id:, attributes:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! attributes: :required if attributes.blank?

          payload = date_attributes(attributes)
          response = Guesty.do_request(
            :put,
            "reservations-v3/#{reservation_id}/dates",
            payload
          )

          raise response.failure if response.failure?

          Success(true)
        end

        private

        # @rbs (::Hash[::Symbol, untyped] attributes) -> ::Hash[::Symbol, untyped]
        def date_attributes(attributes)
          {
            checkInDateLocalized: attributes[:start_date]&.iso8601,
            checkOutDateLocalized: attributes[:end_date]&.iso8601,
            plannedArrival: attributes[:check_in]&.strftime('%H:%M'),
            plannedDeparture: attributes[:check_out]&.strftime('%H:%M'),
            ignoreCalendar: attributes[:ignore_calendar],
            ignoreTerms: attributes[:ignore_terms],
            applyRecalculation: false
          }.compact
        end
      end
    end
  end
end
