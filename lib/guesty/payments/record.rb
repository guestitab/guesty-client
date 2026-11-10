module Guesty
  module Payments
    # Guesty answers 503 PAYMENT_RESERVATION_NOT_READY right after the
    # reservation is created; the ApiError is transient, so retry later.
    class Record
      include Guesty::Operation

      METHODS = %w[RECORDED_CASH ECHECK DEBIT CREDIT BANK_TRANSFER CREDIT_NOTE VOUCHER CHECK OTHER].freeze #: ::Array[::String]
      NOTE_MAX_LENGTH = 500 #: ::Integer

      # @rbs (reservation_id: ::String, attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(reservation_id:, attributes:)
        validate_arguments!(reservation_id:, attributes:)

        Success(request(:post, 'payments/record', payload(reservation_id:, attributes:), retries: 0))
      end

      private

      def validate_arguments!(reservation_id:, attributes:)
        argument! reservation_id: :required if reservation_id.blank?
        argument! attributes: :required if attributes.blank?
        argument! amount: :required if attributes[:amount].blank?
        argument! amount: :must_be_positive if attributes[:amount].present? && attributes[:amount] <= 0
        argument! paid_at: :required if attributes[:paid_at].blank?

        validate_note_and_method!(attributes)
      end

      # @rbs (::Hash[::Symbol, untyped] attributes) -> void
      def validate_note_and_method!(attributes)
        argument! note: :required if attributes[:note].blank?
        argument! note: :invalid if attributes[:note].present? && attributes[:note].length > NOTE_MAX_LENGTH

        method = attributes[:method] || METHODS.first
        argument! method: :invalid unless METHODS.include?(method)
      end

      # @rbs (reservation_id: ::String, attributes: ::Hash[::Symbol, untyped]) -> ::Hash[::Symbol, untyped]
      def payload(reservation_id:, attributes:)
        {
          reservationId: reservation_id,
          amount: attributes[:amount],
          paymentMethod: { method: attributes[:method] || METHODS.first },
          shouldBePaidAt: at(attributes[:paid_at]),
          note: attributes[:note],
          confirmationCode: attributes[:confirmation_code]
        }.compact
      end

      # @rbs (::Time | ::Date value) -> ::String
      def at(value)
        return value.utc.iso8601(3) if value.is_a?(Time)

        Time.utc(value.year, value.month, value.day).iso8601(3)
      end
    end
  end
end
