module Guesty
  module Conversations
    class Search
      include Guesty::Operation

      FIELDS = '_id meta.reservations._id meta.reservations.status'.freeze #: ::String

      # @rbs (external_id: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]?]
      def call(external_id:)
        argument! external_id: :required if external_id.blank?

        conversation = request(:get, 'communication/conversations', query(external_id))[:data][:conversations].first

        Success(conversation && Conversations.summary(conversation))
      end

      private

      def query(external_id)
        {
          fields: FIELDS,
          filters: [{ field: 'reservation._id', operator: '$eq', value: external_id }].to_json,
          limit: 1
        }
      end
    end
  end
end
