module Guesty
  module Reservations
    module Status
      class Cancel
        include Guesty::Operation

        CANCELLED_BY = {
          guest: 'GUEST',
          owner: 'OWNER',
          staff: 'TEAM_MEMBER'
        }.freeze #: ::Hash[::Symbol, ::String]

        # @rbs (reservation_id: ::String, note: ::String, cancelled_by: ::Symbol) -> Dry::Monads::Result[bool]
        def call(reservation_id:, note:, cancelled_by:)
          argument! reservation_id: :required if reservation_id.blank?
          argument! note: :required if note.blank?
          argument! cancelled_by: :invalid unless CANCELLED_BY.key?(cancelled_by)

          Update.new.call!(
            reservation_id:,
            attributes: {
              status: CANCELLED_STATUS,
              cancellationReason: 'No Reason Provided',
              cancellationNote: note,
              canceledBy: CANCELLED_BY.fetch(cancelled_by)
            }
          )

          Success(true)
        end
      end
    end
  end
end
