module Guesty
  module Webhooks
    class Index
      include Guesty::Operation

      # @rbs () -> Dry::Monads::Result[::Array[untyped]]
      def call
        Success(request(:get, 'webhooks'))
      end
    end
  end
end
