module Guesty
  module Guests
    module Profiles
      class Update
        include Guesty::Operation

        # @rbs (guest_id: ::String, attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::Hash[::Symbol, untyped]]
        def call(guest_id:, attributes:)
          argument! guest_id: :required if guest_id.blank?
          argument! attributes: :required, fatal: true if attributes.blank?

          Success(request(:put, "guests-crud/#{guest_id}", prepare_tags(guest_id, attributes)))
        end

        private

        # Actions on a single tag are not supported by Guesty.
        # Instead, we fetch all tags and upload a modified array.
        def prepare_tags(guest_id, attributes)
          tags_to_add = attributes[:addTags] || []
          tags_to_remove = attributes[:removeTags] || []
          payload = attributes.except(:addTags, :removeTags)

          return payload if tags_to_add.blank? && tags_to_remove.blank?

          current_profile = Show.new.call!(guest_id:, fields: ['tags']).value!
          payload.merge(tags: (current_profile[:tags] | tags_to_add) - tags_to_remove)
        end
      end
    end
  end
end
