module Guesty
  module Reservations
    module ConfirmationCode
      # Replaces the confirmation code of a reservation (5-30 characters).
      class Update
        include Guesty::Operation

        LENGTH = 5..30 #: ::Range

        # @rbs (reservation_id: ::String, confirmation_code: ::String) -> Dry::Monads::Result[bool]
        def call(reservation_id:, confirmation_code:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! confirmation_code: :required if confirmation_code.blank?
          argument! confirmation_code: :invalid unless LENGTH.cover?(confirmation_code.length)

          request(:put, "reservations-v3/#{reservation_id}/confirmation-code", { confirmationCode: confirmation_code })

          Success(true)
        end
      end
    end
  end
end
