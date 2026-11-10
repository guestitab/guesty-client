module Guesty
  module Reservations
    module Flags
      # Sets account custom fields on a reservation through CustomFields::Update.
      # The field ids are account-specific, so the host injects them
      # (Guesty.config.custom_fields, keyed by flag name: blacklisted,
      # grants_created, grants_partial).
      class Update
        include Guesty::Operation

        # @rbs (reservation_id: ::String, flags: ::Hash[::Symbol, bool]) -> Dry::Monads::Result[bool]
        def call(reservation_id:, flags:)
          argument! flags: :required if flags.blank?

          custom_fields = flags.map { |name, value| { fieldId: Guesty.config.custom_fields.fetch(name), value: value.to_s } }
          CustomFields::Update.new.call!(reservation_id:, custom_fields:)

          Success(true)
        end
      end
    end
  end
end
