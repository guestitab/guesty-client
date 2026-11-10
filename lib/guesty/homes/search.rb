module Guesty
  module Homes
    class Search
      include Guesty::Operation

      # @rbs (attributes: ::Hash[::Symbol, untyped], ?skip: ::Integer, ?take: ::Integer) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(attributes:, skip: 0, take: 100)
        argument! take: :invalid if take.blank? || take <= 0

        Success(request(:get, 'listings', query(attributes, skip, take)).slice(:results, :count))
      end

      private

      def query(attributes, skip, take)
        {
          active: true,
          fields: Array(attributes[:response_keys]).join(' '),
          limit: take,
          skip:,
          filters: attributes[:filters].presence&.to_json,
          **attributes.fetch(:params, {})
        }.compact_blank
      end
    end
  end
end
