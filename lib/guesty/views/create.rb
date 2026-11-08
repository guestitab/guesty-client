module Guesty
  module Views
    class Create
      include Guesty::Operation

      # @rbs (title: ::String, section: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(title:, section:)
        argument! title: :required if title.blank?
        argument! section: :required if section.blank?

        response = Guesty.do_request :post, 'views', { title:, section: }

        raise response.failure unless response.success?

        Success(response.value!.body)
      end
    end
  end
end
