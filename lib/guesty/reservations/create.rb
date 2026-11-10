module Guesty
  module Reservations
    class Create
      include Guesty::Operation

      REQUIRED_ATTRIBUTE_KEYS = %i[
        guestId
        listingId
        source
        status
        ignoreCalendar
        ignoreTerms
        checkInDateLocalized
        checkOutDateLocalized
      ].freeze #: ::Array[::Symbol]
      GUEST_COUNT_KEYS = %i[numberOfAdults numberOfChildren].freeze #: ::Array[::Symbol]

      # @rbs (attributes: ::Hash[::Symbol, untyped]) -> Dry::Monads::Result[::String]
      def call(attributes:)
        validate_attributes!(attributes)

        Success(request(:post, 'reservations-v3', attributes, retries: 0, timeout: 60).fetch(:reservationId))
      end

      private

      def validate_attributes!(attributes)
        argument! attributes: :required if attributes.blank?

        REQUIRED_ATTRIBUTE_KEYS.each do |key|
          argument! key => :required if attributes[key].nil?
        end

        guests = attributes[:numberOfGuests]
        return unless guests

        GUEST_COUNT_KEYS.each do |key|
          argument! key => :required if guests[key].blank?
        end
      end
    end
  end
end
