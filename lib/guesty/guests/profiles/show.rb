module Guesty
  module Guests
    module Profiles
      class Show
        include Guesty::Operation

        # @rbs (guest_id: ::String, ?fields: ::Array[::String]?) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
        def call(guest_id:, fields: nil)
          argument! guest_id: :required if guest_id.blank?

          Success(request(:get, "guests-crud/#{guest_id}", { fields: fields&.join(' ') }.compact_blank))
        end
      end
    end
  end
end
