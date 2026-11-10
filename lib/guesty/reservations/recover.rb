module Guesty
  module Reservations
    class Recover
      include Guesty::Operation

      # @rbs (confirmation_code: ::String, start_date: ::Date, end_date: ::Date) -> Dry::Monads::Result[::String?]
      def call(confirmation_code:, start_date:, end_date:)
        reservations = Search.new.call!(attributes: { confirmation_code: }, take: 2).value!.fetch(:results)
        match = reservations.find do |reservation|
          reservation[:status] != CANCELLED_STATUS &&
            reservation[:checkInDateLocalized] == start_date.iso8601 &&
            reservation[:checkOutDateLocalized] == end_date.iso8601
        end

        Success(match&.dig(:reservationId))
      end
    end
  end
end
