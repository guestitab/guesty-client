module Guesty
  module Conversations
    class Show
      include Guesty::Operation

      FIELDS = Search::FIELDS #: ::String

      # @rbs (conversation_id: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(conversation_id:)
        argument! conversation_id: :required if conversation_id.blank?

        response = Guesty.do_request(
          :get,
          "communication/conversations/#{conversation_id}",
          { fields: FIELDS }
        )
        return response unless response.success?

        conversation = response.value!.body[:data]

        Success({ id: conversation.fetch(:_id), reservations: Guesty::Reservations.from_conversation(conversation) })
      end
    end
  end
end
