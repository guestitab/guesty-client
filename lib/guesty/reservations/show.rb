module Guesty
  module Reservations
    # A v3 reservation embeds no guest and no money: read the guest (bookerId)
    # through Guests::Profiles::Show and the payout through Payments::Index.
    class Show
      include Guesty::Operation

      # @rbs (reservation_id: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(reservation_id:)
        argument! reservation_id: :required if reservation_id.blank?

        reservation = Index.new.call!(reservation_ids: [reservation_id]).value!.find { |row| row[:_id] == reservation_id }
        error! "Reservation #{reservation_id} not found on Guesty", fatal: true unless reservation

        Success(reservation)
      end
    end
  end
end
