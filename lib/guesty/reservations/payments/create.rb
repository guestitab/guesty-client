module Guesty
  module Reservations
    module Payments
      # Records a payment taken outside Guesty. Idempotent per payment intent:
      # a reservation already fully paid, or with a payment noting the intent,
      # is returned without a post. Reads the payment summary from GET /payments
      # and writes through POST /payments/record (the legacy
      # /reservations/{id}/payments resources retire on 2027-03-01).
      class Create
        include Guesty::Operation

        PAYMENT_METHOD_NAME = 'RECORDED_CASH'.freeze #: ::String
        HISTORY_UNAVAILABLE = 'Guesty has not returned the payment history yet. Try again later.'.freeze #: ::String

        # @rbs (reservation_id: ::String, attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
        def call(reservation_id:, attributes:)
          validate_arguments!(reservation_id:, attributes:)

          @reservation_id = reservation_id

          return Success(summary) if fully_paid? || recorded?(attributes)

          ::Guesty::Payments::Record.new.call(
            reservation_id:,
            attributes: {
              amount: attributes[:amount],
              paid_at: attributes[:paid_at],
              note: note(attributes),
              method: PAYMENT_METHOD_NAME
            }
          )
        end

        private

        def validate_arguments!(reservation_id:, attributes:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! attributes: :required if attributes.blank?
          argument! amount: :required if attributes[:amount].blank?
          argument! amount: :must_be_positive if attributes[:amount].present? && attributes[:amount] <= 0
          argument! paid_at: :required if attributes[:paid_at].blank?
          argument! payment_intent_id: :required if attributes[:payment_intent_id].blank?
        end

        # @rbs () -> ::Hash[::Symbol, untyped]
        def summary
          @summary ||= ::Guesty::Payments::Index.new.call!(reservation_id: @reservation_id).value!
        end

        # @rbs () -> bool
        def fully_paid?
          summary[:isFullyPaid]
        end

        # @rbs (::Hash[::Symbol, untyped] attributes) -> bool
        def recorded?(attributes)
          history = summary[:payments]

          return history.any? { |payment| payment[:note]&.include?(attributes[:payment_intent_id]) } if history
          return false if summary[:totalPaid]&.zero?

          error! HISTORY_UNAVAILABLE
        end

        # @rbs (::Hash[::Symbol, untyped] attributes) -> ::String
        def note(attributes)
          "Payment recorded in Guestit.se / Stripe #{attributes[:payment_intent_id]}"
        end
      end
    end
  end
end
