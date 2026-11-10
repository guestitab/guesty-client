module Guesty
  module Webhooks
    class Create
      include Guesty::Operation

      # @rbs (url: ::String, events: ::Array[::String]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(url:, events:)
        argument! url: :required if url.blank?
        argument! events: :required if events.blank?

        Success(request(:post, 'webhooks', { url:, events: }))
      end
    end
  end
end
