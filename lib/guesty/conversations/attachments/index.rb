module Guesty
  module Conversations
    module Attachments
      # Trades attachment storage keys for signed URLs (they expire after about
      # an hour). Keys that are already links pass through unchanged.
      class Index
        include Guesty::Operation

        BATCH_SIZE = 20
        INVALID_RESPONSE = 'Guesty attachments response has an unexpected shape.'.freeze #: ::String

        # @rbs (keys: ::Array[::String]) -> Dry::Monads::Result[::Hash[::String, ::String]]
        def call(keys:)
          argument! keys: :required, fatal: true if keys.blank?
          argument! keys: :invalid unless keys.all?(&:present?)

          links, storage_keys = keys.uniq.partition { |key| key.start_with?('http://', 'https://') }
          urls = links.index_with(&:itself)

          storage_keys.each_slice(BATCH_SIZE) do |batch|
            urls.merge!(normalize_response(batch, request(:get, 'communication/conversations/get-attachments', { keys: batch })))
          end

          Success(urls)
        end

        private

        # @rbs (::Array[::String] batch, untyped body) -> ::Hash[::String, ::String]
        def normalize_response(batch, body)
          links = body[:data] if body.is_a?(Hash)
          error! INVALID_RESPONSE unless links.is_a?(Array) && links.size == batch.size && links.all? { |link| link.is_a?(String) && link.present? }

          batch.zip(links).to_h
        end
      end
    end
  end
end
