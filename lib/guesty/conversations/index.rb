module Guesty
  module Conversations
    class Index
      include Guesty::Operation

      FIELDS = 'updatedAt meta.reservations._id meta.reservations.status'.freeze #: ::String
      LIMIT = 100
      MAX_PAGES = 20

      # @rbs (since: ::Time) -> Dry::Monads::Result[::Array[::Hash[::Symbol, untyped]]]
      def call(since:)
        conversations = [] #: ::Array[untyped]
        cursor = nil

        MAX_PAGES.times do
          data = request(:get, 'communication/conversations', query(cursor))[:data]
          page = data[:conversations]
          conversations.concat(page.select { |conversation| updated_at(conversation) >= since })

          cursor = data.dig(:cursor, :after)
          return Success(conversations.map { Conversations.summary(it) }) if page.empty? || cursor.blank? || updated_at(page.last) < since
        end

        error! "Guesty conversations pagination exceeded #{MAX_PAGES} pages since #{since.iso8601}"
      end

      private

      # @rbs (::String? cursor) -> ::Hash[::Symbol, untyped]
      def query(cursor)
        { fields: FIELDS, sort: '-updatedAt', limit: LIMIT, cursorAfter: cursor.presence }.compact
      end

      # @rbs (untyped conversation) -> ::Time
      def updated_at(conversation)
        Time.iso8601(conversation.fetch(:updatedAt))
      end
    end
  end
end
