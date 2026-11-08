module Guesty
  module Webhooks
    class Create
      include Guesty::Operation

      # @rbs (url: ::String, events: ::Array[::String]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(url:, events:)
        argument! url: :required if url.blank?
        argument! events: :required if events.blank?

        response = Guesty.do_request :post, 'webhooks', { url:, events: }

        if response.success?
          Success(response.value!.body)
        else
          response
        end
      end
    end
  end
end
