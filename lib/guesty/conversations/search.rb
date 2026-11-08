module Guesty
  module Conversations
    class Search
      include Guesty::Operation

      FIELDS = '_id meta.reservations._id meta.reservations.status'.freeze #: ::String

      # @rbs (external_id: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]?]
      def call(external_id:)
        argument! external_id: :required if external_id.blank?

        response = Guesty.do_request(:get, 'communication/conversations', query(external_id))
        return response unless response.success?

        conversation = response.value!.body[:data][:conversations].first

        Success(conversation && { id: conversation.fetch(:_id), reservations: Guesty::Reservations.from_conversation(conversation) })
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
