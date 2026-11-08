module Guesty
  module Reservations
    # Pre-approves an inquiry (Airbnb only, asynchronous). An inquiry cannot be
    # declined through the API.
    class PreApprove
      include Guesty::Operation

      # @rbs (reservation_id: ::String) -> Dry::Monads::Result[bool]
      def call(reservation_id:)
        argument! reservation_id: :required if reservation_id.blank?

        response = Guesty.do_request(
          :post,
          "reservations-v3/#{reservation_id}/pre-approve",
          retries: 0
        )
        return response unless response.success?

        Success(true)
      end
    end
  end
end
