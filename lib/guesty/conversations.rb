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
  end
end
