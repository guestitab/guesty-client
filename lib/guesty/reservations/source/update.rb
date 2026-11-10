module Guesty
  module Reservations
    module Source
      class Update
        include Guesty::Operation

        # @rbs (reservation_id: ::String, source: ::String, ?point_of_sale: ::String?, ?apply_recalculation: bool?) -> Dry::Monads::Result[bool]
        def call(reservation_id:, source:, point_of_sale: nil, apply_recalculation: nil)
          argument! reservation_id: :required if reservation_id.blank?
          argument! source: :required if source.blank?

          request(:put, "reservations-v3/#{reservation_id}/source", { source:, pointOfSale: point_of_sale, applyRecalculation: apply_recalculation }.compact)

          Success(true)
        end
      end
    end
  end
end
