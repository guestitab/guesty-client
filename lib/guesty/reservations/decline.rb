module Guesty
  module Reservations
    # Declines a request to book. Airbnb answers 422 without a reason; Guesty
    # documents only `dates_not_available`.
    class Decline
      include Guesty::Operation

      # @rbs (reservation_id: ::String, reason: ::String, message: ::String) -> Dry::Monads::Result[bool]
      def call(reservation_id:, reason:, message:)
        argument! reservation_id: :required if reservation_id.blank?
        argument! reason: :required if reason.blank?
        argument! message: :required if message.blank?

        request(:post, "reservations-v3/#{reservation_id}/decline", { reason:, messageToGuest: message }, retries: 0)

        Success(true)
      end
    end
  end
end
