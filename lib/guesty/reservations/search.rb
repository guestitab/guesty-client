module Guesty
  module Reservations
    # Searches the legacy /reservations index (deprecated, switching off at the
    # end of 2026 — new reservation calls use reservations-v3).
    class Search
      include Guesty::Operation

      FILTER_MAPPINGS = {
        ids: { field: '_id', operator: '$in' },
        updated_at: { field: 'lastUpdatedAt', operator: '$gt' },
        conversation_id: { field: 'conversationId', operator: '$eq' },
        status: { field: 'status', operator: '$eq' },
        confirmation_code: { field: 'confirmationCode', operator: '$eq' }
      }.freeze

      # @rbs (::Hash[::Symbol, untyped] attributes) -> ::Array[::Hash[::Symbol, untyped]]
      def self.filters(attributes)
        attributes.map do |key, value|
          normalized = key == :updated_at ? value&.strftime('%Y-%m-%d') : value

          FILTER_MAPPINGS.fetch(key).merge(value: normalized)
        end
      end

      # @rbs (fields: ::Array[::String], attributes: ::Hash[::Symbol, untyped], ?skip: ::Integer, ?take: ::Integer) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(fields:, attributes:, skip: 0, take: 100)
        validate_arguments!(fields:, attributes:, take:)

        response = Guesty.do_request(:get, 'reservations', params(fields:, attributes:, skip:, take:))
        return response unless response.success?

        body = response.value!.body
        result = {
          results: body[:results],
          count: body[:count]
        }

        Success(result)
      end

      private

      def validate_arguments!(fields:, attributes:, take:)
        argument! fields: :required, fatal: true if fields.blank?
        argument! attributes: :required if attributes.blank?
        argument! take: :invalid if take && take <= 0
        argument! attributes: :invalid unless attributes.keys.all? { |name| FILTER_MAPPINGS.key?(name) }
        argument! updated_at: :required if attributes.key?(:updated_at) && attributes[:updated_at].blank?
        argument! ids: :required if attributes.key?(:ids) && attributes[:ids].empty?
      end

      def params(fields:, attributes:, skip:, take:)
        {
          filters: self.class.filters(attributes).to_json,
          sort: 'createdAt',
          limit: take,
          skip:,
          fields: fields.join(' ')
        }
      end
    end
  end
end
