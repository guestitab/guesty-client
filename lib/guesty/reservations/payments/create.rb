module Guesty
  module Reservations
    module Payments
      # Records a payment taken outside Guesty. Idempotent per payment intent:
      # a reservation already fully paid, or with a payment noting the intent,
      # is returned without a post.
      class Create
        include Guesty::Operation

        PAYMENT_METHOD_NAME = 'RECORDED_CASH'.freeze #: ::String
        HISTORY_UNAVAILABLE = 'Guesty has not returned the payment history yet. Try again later.'.freeze #: ::String

        # @rbs (reservation_id: ::String, attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
        def call(reservation_id:, attributes:)
          validate_arguments!(reservation_id:, attributes:)

          @reservation_id = reservation_id

          return Success(reservation) if fully_paid? || recorded?(attributes)

          response = Guesty.do_request :post, "reservations/#{reservation_id}/payments", payload(attributes), retries: 0
          return response unless response.success?

          Success(response.value!.body)
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
        def reservation
          @reservation ||= Show.new.call!(reservation_id: @reservation_id, fields: %w[money.isFullyPaid money.payments money.totalPaid]).value!
        end

        # @rbs () -> bool
        def fully_paid?
          reservation[:money][:isFullyPaid]
        end

        # @rbs (::Hash[::Symbol, untyped] attributes) -> bool
        def recorded?(attributes)
          payments = reservation[:money][:payments]

          return payments.any? { |payment| payment[:note]&.include?(attributes[:payment_intent_id]) } if payments
          return false if reservation[:money][:totalPaid]&.zero?

          error! HISTORY_UNAVAILABLE
        end

        # @rbs (::Hash[::Symbol, untyped] attributes) -> ::Hash[::Symbol, untyped]
        def payload(attributes)
          {
            paymentMethod: {
              method: PAYMENT_METHOD_NAME
            },
            amount: attributes[:amount],
            paidAt: attributes[:paid_at].strftime('%Y-%m-%d'),
            note: "Payment recorded in Guestit.se / Stripe #{attributes[:payment_intent_id]}"
          }
        end
      end
    end
  end
end
