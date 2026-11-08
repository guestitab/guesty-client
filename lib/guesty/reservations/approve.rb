module Guesty
  module Reservations
    # Approves a request to book (a reservation in status `reserved`). Runs
    # asynchronously on Guesty's side; a repeat answers 400 DUPLICATE.
    class Approve
      include Guesty::Operation

      # @rbs (reservation_id: ::String) -> Dry::Monads::Result[bool]
      def call(reservation_id:)
        argument! reservation_id: :required if reservation_id.blank?

        response = Guesty.do_request(
          :post,
          "reservations-v3/#{reservation_id}/approve",
          retries: 0
        )
        return response unless response.success?

        Success(true)
      end
    end
  end
end
