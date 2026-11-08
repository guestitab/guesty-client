module Guesty
  module Guests
    module Profiles
      class Show
        include Guesty::Operation

        # @rbs (guest_id: ::String, ?fields: ::Array[::String]?) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
        def call(guest_id:, fields: nil)
          argument! guest_id: :required if guest_id.blank?

          attributes = {} #: ::Hash[::Symbol, ::String]
          attributes[:fields] = fields.join(' ') if fields.present?

          response = Guesty.do_request :get, "guests-crud/#{guest_id}", attributes

          raise response.failure unless response.success?

          Success(response.value!.body)
        end
      end
    end
  end
end
