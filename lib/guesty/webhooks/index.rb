module Guesty
  module Webhooks
    class Index
      include Guesty::Operation

      # @rbs () -> Dry::Monads::Result[::Array[untyped]]
      def call
        response = Guesty.do_request :get, 'webhooks'

        if response.success?
          Success(response.value!.body)
        else
          response
        end
      end
    end
  end
end
