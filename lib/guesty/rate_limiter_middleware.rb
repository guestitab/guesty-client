module Guesty
  # Faraday request middleware delegating throttling to the injected limiter
  # (Guesty.config.rate_limiter), so a host can share the windows across
  # processes. Registered as :guesty_rate_limiter.
  class RateLimiterMiddleware < Faraday::Middleware
    # @rbs (untyped app, ?::Hash[::Symbol, untyped] options) -> void
    def initialize(app, options = {})
      super

      @key = options[:key]
      @threshold = options[:threshold]
      @interval = options[:interval]
    end

    def on_request(_env)
      key = @key.is_a?(Proc) ? @key.call : @key

      Guesty.config.rate_limiter.throttle!(key:, threshold: @threshold, interval: @interval)
    end
  end

  Faraday::Request.register_middleware(guesty_rate_limiter: RateLimiterMiddleware)
end
