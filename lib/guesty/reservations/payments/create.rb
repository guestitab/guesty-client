module Guesty
  module Reservations
    module Payments
      # Records a payment taken outside Guesty through Payments::Record.
      # Idempotent per payment intent: a reservation already fully paid, or with
      # a payment noting the intent, returns the Payments::Index summary without
      # a post. The arguments are checked here, before that read.
      class Create
        include Guesty::Operation

        HISTORY_UNAVAILABLE = 'Guesty has not returned the payment history yet. Try again later.'.freeze #: ::String

        # @rbs (reservation_id: ::String, attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
        def call(reservation_id:, attributes:)
          validate_arguments!(reservation_id:, attributes:)

          summary = ::Guesty::Payments::Index.new.call!(reservation_id:).value!
          return Success(summary) if summary[:isFullyPaid] || recorded?(summary, attributes[:payment_intent_id])

          ::Guesty::Payments::Record.new.call(
            reservation_id:,
            attributes: { amount: attributes[:amount], paid_at: attributes[:paid_at], note: note(attributes[:payment_intent_id]) }
          )
        end

        private

        def validate_arguments!(reservation_id:, attributes:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! attributes: :required if attributes.blank?
          argument! amount: :required if attributes[:amount].blank?
          argument! amount: :must_be_positive if attributes[:amount] <= 0
          argument! paid_at: :required if attributes[:paid_at].blank?
          argument! payment_intent_id: :required if attributes[:payment_intent_id].blank?
        end

        # @rbs (::Hash[::Symbol, untyped] summary, ::String payment_intent_id) -> bool
        def recorded?(summary, payment_intent_id)
          history = summary[:payments]

          return history.any? { |payment| payment[:note]&.include?(payment_intent_id) } if history
          return false if summary[:totalPaid]&.zero?

          error! HISTORY_UNAVAILABLE
        end

        # @rbs (::String payment_intent_id) -> ::String
        def note(payment_intent_id)
          "Payment recorded in Guestit.se / Stripe #{payment_intent_id}"
        end
      end
    end
  end
end
