module Guesty
  module Conversations
    module Posts
      class Since
        include Guesty::Operation

        MAX_PAGES = 20

        # @rbs (conversation_id: ::String, ?since: ::Time?) -> Dry::Monads::Result[::Array[untyped]]
        def call(conversation_id:, since: nil)
          argument! conversation_id: :required if conversation_id.blank?

          posts = [] #: ::Array[untyped]
          cursor = nil #: ::String?

          MAX_PAGES.times do
            page = Index.new.call!(conversation_id:, cursor:).value!
            posts.concat(page.fetch(:results))

            cursor = page.fetch(:cursor_after)
            return Success(posts) if cursor.nil? || reached?(since, page.fetch(:oldest_created_at))
          end

          error! "Guesty conversation #{conversation_id} pagination exceeded #{MAX_PAGES} pages", fatal: true
        end

        private

        # @rbs (::Time? since, ::Time? oldest_created_at) -> bool
        def reached?(since, oldest_created_at)
          since.present? && oldest_created_at.present? && oldest_created_at <= since
        end
      end
    end
  end
end
