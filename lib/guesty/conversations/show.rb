module Guesty
  module Conversations
    class Show
      include Guesty::Operation

      FIELDS = Search::FIELDS #: ::String

      # @rbs (conversation_id: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(conversation_id:)
        argument! conversation_id: :required if conversation_id.blank?

        Success(Conversations.summary(request(:get, "communication/conversations/#{conversation_id}", { fields: FIELDS })[:data]))
      end
    end
  end
end
