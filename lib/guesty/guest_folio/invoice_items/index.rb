module Guesty
  module GuestFolio
    module InvoiceItems
      # Negative amounts are refunds, positive amounts guest charges.
      class Index
        include Guesty::Operation

        FIELDS = %w[normalType totalPrice logs.createdAt].freeze #: ::Array[::String]
        INVALID_RESPONSE = 'Guesty invoice items response has an unexpected shape.'.freeze #: ::String

        # @rbs (reservation_id: ::String) -> Dry::Monads::Result[::Array[untyped]]
        def call(reservation_id:)
          argument! reservation_id: :required if reservation_id.blank?

          Success(normalize_response(request(:get, 'guest-folio/invoice-items', query(reservation_id)), reservation_id))
        end

        private

        # @rbs (::String reservation_id) -> ::Hash[::Symbol, ::String]
        def query(reservation_id)
          {
            reservationIds: reservation_id,
            fields: FIELDS.join(',')
          }
        end

        # @rbs (untyped body, ::String reservation_id) -> ::Array[untyped]
        def normalize_response(body, reservation_id)
          results = body[:results] if body.is_a?(Hash)
          error! INVALID_RESPONSE unless results.is_a?(Array)

          result = results.find { |row| row[:reservationId] == reservation_id }
          return [] if result.nil?

          items = result[:invoiceItems]
          error! INVALID_RESPONSE unless items.is_a?(Array) && result[:currency].present?

          items.map { |item| normalize_item(item, result.fetch(:currency)) }
        end

        # @rbs (untyped item, ::String currency) -> untyped
        def normalize_item(item, currency)
          created_at = item.dig(:logs, :createdAt)

          {
            external_id: item.fetch(:id),
            normal_type: item[:normalType],
            amount: item[:totalPrice]&.to_d,
            currency:,
            occurred_at: (Time.iso8601(created_at) if created_at.present?)
          }
        end
      end
    end
  end
end
