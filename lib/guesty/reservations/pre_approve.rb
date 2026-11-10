module Guesty
  module Reservations
    # Airbnb only. An inquiry cannot be declined through the API.
    class PreApprove
      include Guesty::Operation

      # @rbs (reservation_id: ::String) -> Dry::Monads::Result[bool]
      def call(reservation_id:)
        argument! reservation_id: :required if reservation_id.blank?

        request(:post, "reservations-v3/#{reservation_id}/pre-approve", retries: 0)

        Success(true)
      end
    end
  end
end
