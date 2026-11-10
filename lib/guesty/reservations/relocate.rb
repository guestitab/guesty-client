module Guesty
  module Reservations
    # Moves a reservation to another listing (the legacy listingId update on
    # PUT /reservations/{id} retires on 2027-03-01).
    class Relocate
      include Guesty::Operation

      # @rbs (reservation_id: ::String, listing_id: ::String, ?ignore_calendar: bool?, ?ignore_terms: bool?, ?ignore_blocks: bool?) -> Dry::Monads::Result[bool]
      def call(reservation_id:, listing_id:, ignore_calendar: nil, ignore_terms: nil, ignore_blocks: nil)
        argument! reservation_id: :required if reservation_id.blank?
        argument! listing_id: :required if listing_id.blank?

        body = { listingId: listing_id, ignoreCalendar: ignore_calendar, ignoreTerms: ignore_terms, ignoreBlocks: ignore_blocks }.compact
        request(:put, "reservations-v3/#{reservation_id}/relocate", body)

        Success(true)
      end
    end
  end
end
