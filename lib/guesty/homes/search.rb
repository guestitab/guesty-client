module Guesty
  module Homes
    # `active` is a filter, so all listings take two passes. Tags come back as
    # ids on the listing; tag names live on GET listings/tags.
    class Search
      include Guesty::Operation

      # @example
      #   attributes: {
      #     params: { ids: 'guestyID', available: { checkIn: "YYYY-MM-DD", checkOut: "YYYY-MM-DD", minOccupancy: 3 }.to_json }
      #     filters: [{ operator: '$eq', field: 'type', value: 'MTL_CHILD' }],
      #     response_keys: %w[
      #       _id
      #       nickname
      #       type
      #     ]
      #   }

      # @rbs (attributes: ::Hash[::Symbol, untyped], ?skip: ::Integer, ?take: ::Integer) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(attributes:, skip: 0, take: 100)
        argument! take: :invalid if take.blank? || take <= 0

        response = Guesty.do_request :get, 'listings', query(attributes, skip, take)

        raise response.failure unless response.success?

        body = response.value!.body

        Success(body.slice(:results, :count))
      end

      private

      def query(attributes, skip, take)
        {
          active: true,
          fields: (attributes[:response_keys] || []).join(' '),
          limit: take,
          skip:,
          **(attributes[:filters].present? ? { filters: attributes[:filters].to_json } : {}),
          **(attributes[:params] || {})
        }.compact_blank
      end
    end
  end
end
