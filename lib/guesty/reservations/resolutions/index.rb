module Guesty
  module Reservations
    module Resolutions
      # Airbnb Resolution Center: Guesty lists only closed resolutions, about a day after Airbnb closes them,
      # and filters them by their creation time.
      class Index
        include Guesty::Operation

        CLOSED_STATE = 'closed'.freeze #: ::String
        INVALID_RESPONSE = 'Guesty resolutions response has an unexpected shape.'.freeze #: ::String

        # @rbs (reservation_id: ::String, created_at: ::Range[::Time | ::ActiveSupport::TimeWithZone]) -> Dry::Monads::Result[::Array[untyped]]
        def call(reservation_id:, created_at:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! created_at: :invalid unless created_at.is_a?(Range) && created_at.begin && created_at.end

          body = request(:get, "airbnb-resolutions-center/reservations/#{reservation_id}/resolutions", query(created_at))

          Success(normalize_response(body))
        end

        private

        # @rbs (::Range[::Time | ::ActiveSupport::TimeWithZone] created_at) -> ::Hash[::Symbol, ::String]
        def query(created_at)
          {
            from: created_at.begin.utc.iso8601,
            to: created_at.end.utc.iso8601
          }
        end

        # @rbs (untyped body) -> ::Array[untyped]
        def normalize_response(body)
          resolutions = body[:resolutions] if body.is_a?(Hash)
          error! INVALID_RESPONSE unless resolutions.is_a?(Array)

          resolutions.map { |resolution| normalize_resolution(resolution) }
        end

        # @rbs (untyped resolution) -> untyped
        def normalize_resolution(resolution)
          updated_at = resolution[:airbnbUpdatedAt]

          {
            external_id: resolution.fetch(:resolutionId),
            state: resolution[:statusName]&.downcase,
            amount_paid: resolution[:totalAmountPaid]&.to_d,
            currency: resolution[:currency],
            closed_at: (Time.iso8601(updated_at) if updated_at.present?)
          }
        end
      end
    end
  end
end
