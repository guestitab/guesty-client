module Guesty
  module Guests
    module Profiles
      class Create
        include Guesty::Operation

        REQUIRED_ATTRIBUTES = %i[firstName lastName].freeze #: ::Array[::Symbol]

        # @rbs (attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
        def call(attributes:)
          argument! attributes: :required, fatal: true if attributes.blank?

          missing = REQUIRED_ATTRIBUTES.find { |attribute| attributes[attribute].blank? }
          argument! missing => :required if missing

          response = Guesty.do_request :post, 'guests-crud', attributes, retries: 0

          raise response.failure unless response.success?

          Success(response.value!.body)
        end
      end
    end
  end
end
