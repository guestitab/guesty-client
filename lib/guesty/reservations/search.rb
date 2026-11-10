module Guesty
  module Reservations
    # Rows are lean, keyed by reservationId. There is no lastUpdatedAt filter:
    # follow updates through the reservation.updated.v2 webhook.
    class Search
      include Guesty::Operation

      FILTER_MAPPINGS = {
        status: { field: 'status' },
        confirmation_code: { field: 'confirmationCode' },
        listing_id: { field: 'listingId' },
        source: { field: 'source' },
        check_in: { field: 'checkIn', range: :date },
        check_out: { field: 'checkOut', range: :date },
        created_at: { field: 'createdAt', range: :datetime }
      }.freeze

      SORTS = %w[_id -_id checkIn -checkIn checkOut -checkOut createdAt -createdAt].freeze #: ::Array[::String]
      TAKE = 100 #: ::Integer # Max allowed by the Guesty API

      # @rbs (::Hash[::Symbol, untyped] attributes) -> ::Array[::Hash[::Symbol, ::String]]
      def self.filters(attributes)
        attributes.flat_map do |key, value|
          mapping = FILTER_MAPPINGS.fetch(key)
          next [{ name: "filter[#{mapping[:field]}]", value: Array.wrap(value).join(',') }] unless mapping[:range]

          range_entries(mapping.fetch(:range), mapping.fetch(:field), value)
        end
      end

      # @rbs (::Symbol kind, ::String field, ::Range range) -> ::Array[::Hash[::Symbol, ::String]]
      def self.range_entries(kind, field, range)
        entries = []
        entries << { name: "filter[#{field}][gte]", value: range_bound(kind, range.begin) } if range.begin
        entries << { name: "filter[#{field}][#{range.exclude_end? ? 'lt' : 'lte'}]", value: range_bound(kind, range.end) } if range.end

        entries
      end
      private_class_method :range_entries

      # @rbs (::Symbol kind, untyped value) -> ::String
      def self.range_bound(kind, value)
        kind == :date ? value.strftime('%Y-%m-%d') : value.iso8601
      end
      private_class_method :range_bound

      # @rbs (attributes: ::Hash[::Symbol, untyped], ?skip: ::Integer, ?take: ::Integer, ?sort: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(attributes:, skip: 0, take: TAKE, sort: 'createdAt')
        validate_arguments!(attributes:, take:, sort:)

        Success(request(:get, 'reservations-v3/search', params(attributes:, skip:, take:, sort:)).slice(:results, :pagination))
      end

      private

      def validate_arguments!(attributes:, take:, sort:)
        argument! attributes: :required if attributes.blank?
        argument! take: :invalid if take <= 0
        argument! sort: :invalid unless SORTS.include?(sort)
        argument! attributes: :invalid unless attributes.keys.all? { |name| FILTER_MAPPINGS.key?(name) }

        attributes.each { |key, value| validate_filter!(key, value) }
      end

      # @rbs (::Symbol key, untyped value) -> void
      def validate_filter!(key, value)
        mapping = FILTER_MAPPINGS.fetch(key)

        if mapping[:range]
          argument! key => :invalid unless value.is_a?(Range) && (value.begin || value.end)
        elsif value.blank?
          argument! key => :required
        end
      end

      # @rbs (attributes: ::Hash[::Symbol, untyped], skip: ::Integer, take: ::Integer, sort: ::String) -> ::Hash[::String, untyped]
      def params(attributes:, skip:, take:, sort:)
        self.class.filters(attributes).to_h { |entry| [entry[:name], entry[:value]] }.merge(
          'sort' => sort,
          'limit' => take,
          'skip' => skip
        )
      end
    end
  end
end
