module Guesty
  module Webhooks
    class Update
      include Guesty::Operation

      # @rbs (id: ::String, url: ::String, events: ::Array[::String]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(id:, url:, events:)
        argument! id: :required if id.blank?
        argument! url: :required if url.blank?
        argument! events: :required if events.blank?

        Success(request(:put, "webhooks/#{id}", { url:, events: }))
      end
    end
  end
end
