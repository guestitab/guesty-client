module Guesty
  module Reservations
    # Finds the Guesty reservation matching a confirmation code and stay window,
    # skipping canceled ones. Returns nil when none matches.
    class Recover
      include Guesty::Operation

      # @rbs (confirmation_code: ::String, start_date: ::Date, end_date: ::Date) -> Dry::Monads::Result[::String?]
      def call(confirmation_code:, start_date:, end_date:)
        result = Guesty::Reservations::Search.new.call!(
          attributes: { confirmation_code: },
          take: 2
        ).value!
        candidate = result.fetch(:results).find do |reservation|
          reservation[:status] != CANCELLED_STATUS &&
            reservation[:checkInDateLocalized] == start_date.iso8601 &&
            reservation[:checkOutDateLocalized] == end_date.iso8601
        end

        Success(candidate&.dig(:reservationId))
      end
    end
  end
end
