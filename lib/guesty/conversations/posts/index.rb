module Guesty
  module Conversations
    module Posts
      class Index
        include Guesty::Operation

        LIMIT = 500
        LOG_SENDER = 'log'.freeze #: ::String
        SENDERS = ['guest', 'host', LOG_SENDER].freeze #: ::Array[::String]
        SYSTEM_MODULE_TYPES = %w[note aiSummary].freeze #: ::Array[::String]
        INVALID_RESPONSE = 'Guesty posts response has an unexpected shape.'.freeze #: ::String

        # @rbs (conversation_id: ::String, ?cursor: ::String?) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
        def call(conversation_id:, cursor: nil)
          argument! conversation_id: :required if conversation_id.blank?

          response = Guesty.do_request(
            :get,
            "communication/conversations/#{conversation_id}/posts",
            query(cursor)
          )
          return response unless response.success?

          Success(normalize_response(response.value!.body[:data]))
        end

        private

        # @rbs (untyped data) -> ::Hash[::Symbol, untyped]
        def normalize_response(data)
          raw_posts = data.is_a?(Hash) ? data[:posts] : nil #: ::Array[untyped]?
          error! INVALID_RESPONSE unless raw_posts.is_a?(Array)

          posts = raw_posts.filter_map { |post| normalize_post(post) }
          { results: posts, cursor_after: data.dig(:cursor, :after).presence, oldest_created_at: oldest_created_at(raw_posts) }
        end

        # Taken before the filter. A page of only skipped post types must still tell the caller
        # how far back it reached.
        # @rbs (::Array[untyped] raw_posts) -> ::Time?
        def oldest_created_at(raw_posts)
          raw_posts.filter_map { |post| Time.iso8601(post[:createdAt]) if post[:createdAt].present? }.min
        end

        def query(cursor)
          params = { limit: LIMIT, sort: '-createdAt' }
          params[:cursorAfter] = cursor if cursor.present?
          params
        end

        def normalize_attachments(attachments)
          attachments.map { |attachment| attachment_media_type(attachment[:type]) }
        end

        # Parallel to #normalize_attachments. Index N names the same attachment in both arrays,
        # so a missing attachmentUrl keeps its slot as an empty string.
        def normalize_attachment_keys(attachments)
          attachments.map { |attachment| attachment[:attachmentUrl].to_s }
        end

        def attachment_media_type(type)
          return 'application/octet-stream' unless type.is_a?(String) && type.present?
          return type if type.include?('/')

          MiniMime.lookup_by_extension(type)&.content_type || 'application/octet-stream'
        end

        # Guesty allows a post that is only an attachment. A post with neither text nor a file
        # carries nothing. Provider-side automation posts stay visible so the host does not answer a
        # turn that was already answered.
        def importable?(post, attachments)
          return false if post[:_id].blank? || post[:createdAt].blank?
          return false if SYSTEM_MODULE_TYPES.include?(post.dig(:module, :type))

          SENDERS.include?(post[:sentBy]) && (post[:body].present? || attachments.any?)
        end

        # provider_reservation_id routes the post to its stay and author_name lands on the sync row; neither is a message column.
        # @rbs (untyped post) -> untyped
        def normalize_post(post)
          raw_attachments = post.fetch(:attachments, [])
          attachments = normalize_attachments(raw_attachments)
          return unless importable?(post, attachments)

          {
            provider_message_id: post[:_id],
            sender_kind: sender_kind(post),
            body: post[:body] || '',
            attachments:,
            attachment_keys: normalize_attachment_keys(raw_attachments),
            module_type: channel_type(post),
            provider_reservation_id: post.dig(:module, :reservationId),
            provider_occurred_at: Time.iso8601(post[:createdAt]),
            author_name: author_name(post)
          }
        end

        # Guesty's own scheduled posts and reservation logs are system posts. Everything else keeps the sender
        # Guesty names.
        # @rbs (untyped post) -> String
        def sender_kind(post)
          post[:isAutomatic] || post[:sentBy] == LOG_SENDER ? 'system' : post[:sentBy]
        end

        # @rbs (untyped post) -> String?
        def channel_type(post)
          post.dig(:module, :type) unless post[:sentBy] == LOG_SENDER
        end

        # Only a person answering from Guesty has a name worth keeping.
        # @rbs (untyped post) -> String?
        def author_name(post)
          return if post[:isAutomatic] || post[:sentBy] != 'host'

          name = post.dig(:from, :fullName)
          name.presence if name.is_a?(String)
        end
      end
    end
  end
end
