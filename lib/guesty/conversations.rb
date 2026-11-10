module Guesty
  module Conversations
    # Neutral channel names for Guesty's versioned module types.
    CHANNELS = {
      'airbnb2' => 'airbnb',
      'bookingCom' => 'booking_com'
    }.freeze #: ::Hash[::String, ::String]
    VERSION_SUFFIX = /\d+\z/ #: ::Regexp

    # @rbs (::String module_type) -> ::String
    def self.channel(module_type)
      CHANNELS.fetch(module_type) { module_type.sub(VERSION_SUFFIX, '') }
    end

    # The conversation id and its reservations, as Index, Search and Show return them.
    # @rbs (untyped conversation) -> ::Hash[::Symbol, untyped]
    def self.summary(conversation)
      { id: conversation.fetch(:_id), reservations: Reservations.from_conversation(conversation) }
    end
  end
end
