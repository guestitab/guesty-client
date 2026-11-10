module Guesty
  module Conversations
    module Messages
      class Reply
        include Guesty::Operation

        # @rbs (conversation_id: String, body: String, ?module_type: String?) -> Dry::Monads::Result[Hash[Symbol, untyped]]
        def call(conversation_id:, body:, module_type: nil)
          argument! conversation_id: :required, fatal: true if conversation_id.blank?
          argument! body: :required, fatal: true if body.blank?
          argument! module_type: :invalid, fatal: true if !module_type.nil? && module_type.blank?

          # On `platform` Guesty picks the booking channel, or email, and echoes the channel it used.
          post = request(:post, "communication/conversations/#{conversation_id}/send-message", { module: { type: module_type || 'platform' }, body: }, retries: 0)

          Success(normalize(post.fetch(:data)))
        end

        private

        def normalize(post)
          {
            message_id: post.fetch(:_id),
            conversation_id: post.fetch(:conversationId),
            module_type: post.dig(:module, :type),
            body: post.fetch(:body),
            created_at: Time.iso8601(post.fetch(:createdAt))
          }
        end
      end
    end
  end
end
