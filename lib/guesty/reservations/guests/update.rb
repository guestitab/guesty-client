module Guesty
  module Reservations
    module Guests
      # Updates the guest count breakdown of a reservation (guestsCount and
      # numberOfGuests). Financial recalculation is applied automatically by
      # Guesty.
      class Update
        include Guesty::Operation

        # @rbs (reservation_id: ::String, attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[bool]
        def call(reservation_id:, attributes:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! attributes: :required if attributes.blank?
          argument! num_guests: :required if attributes[:num_guests].blank?

          response = Guesty.do_request(:put, "reservations-v3/#{reservation_id}/guests", payload(attributes))

          raise response.failure if response.failure?

          Success(true)
        end

        private

        # @rbs (::Hash[::Symbol, untyped] attributes) -> ::Hash[::Symbol, untyped]
        def payload(attributes)
          {
            guestsCount: attributes[:num_guests],
            numberOfGuests: number_of_guests(attributes),
            ignoreCalendar: attributes[:ignore_calendar],
            ignoreTerms: attributes[:ignore_terms],
            ignoreBlocks: attributes[:ignore_blocks]
          }.compact
        end

        # @rbs (::Hash[::Symbol, untyped] attributes) -> ::Hash[::Symbol, untyped]?
        def number_of_guests(attributes)
          {
            numberOfAdults: attributes[:adults],
            numberOfChildren: attributes[:children],
            numberOfInfants: attributes[:infants],
            numberOfPets: attributes[:pets]
          }.compact.presence
        end
      end
    end
  end
end
