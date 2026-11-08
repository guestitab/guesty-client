module Guesty
  class Error < StandardError
    attr_reader :fatal

    # @rbs (?::String message, ?fatal: bool) -> void
    def initialize(message = nil, fatal: false)
      @fatal = fatal

      super(message)
    end
  end

  # Raised by operations before any network call when the arguments are unusable.
  # fatal: true marks a refusal no retry can fix; the host decides what to do with it.
  class ArgumentError < Error; end

  # Raised by the rate limiter middleware when the injected limiter refuses the
  # request: the call never left the process, so no write landed upstream.
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
