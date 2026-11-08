module Guesty
  module Conversations
    class Index
      include Guesty::Operation

      FIELDS = 'updatedAt meta.reservations._id meta.reservations.status'.freeze #: ::String
      LIMIT = 100
      MAX_PAGES = 20

      # @rbs (since: ::Time) -> Dry::Monads::Result[::Array[::Hash[::Symbol, untyped]]]
      def call(since:)
        results = collect_updated(since)

        Success(results)
      end

      private

      def collect_updated(since)
        results = [] #: ::Array[untyped]
        cursor_after = nil

        MAX_PAGES.times do
          data = fetch_page(cursor_after)
          page = data[:conversations].map { |conversation| normalize(conversation) }
          results.concat(page.select { |conversation| conversation[:updated_at] >= since })

          cursor_after = data.dig(:cursor, :after)
          return without_timestamps(results) if page.empty? || cursor_after.blank? || page.last[:updated_at] < since
        end

        error! "Guesty conversations pagination exceeded #{MAX_PAGES} pages since #{since.iso8601}"
      end

      def without_timestamps(conversations)
        conversations.map { |conversation| conversation.except(:updated_at) }
      end

      def fetch_page(cursor_after)
        params = { fields: FIELDS, sort: '-updatedAt', limit: LIMIT }
        params[:cursorAfter] = cursor_after if cursor_after.present?

        response = Guesty.do_request(:get, 'communication/conversations', params)
        error! response.failure.message unless response.success?

        response.value!.body[:data]
      end

      def normalize(conversation)
        {
          id: conversation.fetch(:_id),
          updated_at: Time.iso8601(conversation.fetch(:updatedAt)),
          reservations: Guesty::Reservations.from_conversation(conversation)
        }
      end
    end
  end
end
