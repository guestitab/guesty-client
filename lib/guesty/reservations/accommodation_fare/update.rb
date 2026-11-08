module Guesty
  module Reservations
    module AccommodationFare
      class Update
        include Guesty::Operation

        FARE_TYPES = %w[AF AFA AFD].freeze #: ::Array[::String]
        ADJUSTED_TYPE = 'AF'.freeze #: ::String

        # @rbs (reservation_id: ::String, amount: ::Integer | ::Float | ::BigDecimal) -> Dry::Monads::Result[::BigDecimal]
        def call(reservation_id:, amount:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! amount: :negative, fatal: true if amount.negative?

          adjustment = amount.to_d - current_fare(reservation_id)
          return Success(adjustment) if adjustment.zero?

          response = Guesty.do_request :post, 'price-adjustments/manual-total-amount', payload(reservation_id, adjustment), retries: 0
          return response unless response.success?

          Success(adjustment)
        end

        private

        # @rbs (::String reservation_id) -> ::BigDecimal
        def current_fare(reservation_id)
          reservation = Show.new.call!(reservation_id:, fields: %w[money.invoiceItems]).value!
          items = reservation.dig(:money, :invoiceItems)

          items.select { |item| FARE_TYPES.include?(item[:normalType]) }.sum(BigDecimal('0')) { |item| item[:amount].to_d }
        end

        # @rbs (::String reservation_id, ::BigDecimal adjustment) -> ::Hash[::Symbol, untyped]
        def payload(reservation_id, adjustment)
          {
            reservationId: reservation_id,
            priceAdjustments: [{ normalType: ADJUSTED_TYPE, amount: adjustment.to_f }]
          }
        end
      end
    end
  end
end
