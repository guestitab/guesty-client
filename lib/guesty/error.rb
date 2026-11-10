module Guesty
  class Error < StandardError
    attr_reader :fatal

    # @rbs (?::String message, ?fatal: bool) -> void
    def initialize(message = nil, fatal: false)
      @fatal = fatal

      super(message)
    end
  end

  class ArgumentError < Error; end

  class ThrottledError < Error
    attr_reader :key, :threshold, :interval, :retry_after

    # @rbs (key: ::Symbol, threshold: ::Integer, interval: untyped, retry_after: untyped) -> void
    def initialize(key:, threshold:, interval:, retry_after:)
      @key = key
      @threshold = threshold
      @interval = interval
      @retry_after = retry_after

      super("Rate limit exceeded for #{key}")
    end
  end
end
