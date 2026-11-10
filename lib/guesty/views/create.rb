module Guesty
  module Views
    class Create
      include Guesty::Operation

      # @rbs (title: ::String, section: ::String) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
      def call(title:, section:)
        argument! title: :required if title.blank?
        argument! section: :required if section.blank?

        Success(request(:post, 'views', { title:, section: }))
      end
    end
  end
end
