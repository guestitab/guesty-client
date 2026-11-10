module Guesty
  module Conversations
    CHANNELS = {
      'airbnb2' => 'airbnb',
      'bookingCom' => 'booking_com'
    }.freeze #: ::Hash[::String, ::String]
    VERSION_SUFFIX = /\d+\z/ #: ::Regexp

    # @rbs (::String module_type) -> ::String
    def self.channel(module_type)
      CHANNELS.fetch(module_type) { module_type.sub(VERSION_SUFFIX, '') }
    end

    # @rbs (untyped conversation) -> ::Hash[::Symbol, untyped]
    def self.summary(conversation)
      { id: conversation.fetch(:_id), reservations: Reservations.from_conversation(conversation) }
    end
  end
end
