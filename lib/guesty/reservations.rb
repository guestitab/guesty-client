module Guesty
  module Reservations
    CANCELLED_STATUS = 'canceled'.freeze #: ::String
    CLOSED_STATUSES = %w[canceled closed declined expired].freeze #: ::Array[::String]

    # @rbs (untyped conversation) -> ::Array[::Hash[::Symbol, untyped]]
    def self.from_conversation(conversation)
      (conversation.dig(:meta, :reservations) || []).filter_map do |reservation|
        { id: reservation[:_id], closed: CLOSED_STATUSES.include?(reservation[:status]) } if reservation[:_id]
      end
    end
  end
end
