module Guesty
  # Faraday request middleware delegating throttling to the injected limiter
  # (Guesty.config.rate_limiter), so a host can share the windows across
  # processes. Registered as :guesty_rate_limiter; options are threshold:,
  # interval: and a key: lambda, resolved per request for the current slot.
  class RateLimiterMiddleware < Faraday::Middleware
    # @rbs (untyped env) -> void
    def on_request(_env)
      Guesty.config.rate_limiter.throttle!(key: options[:key].call, threshold: options[:threshold], interval: options[:interval])
    end
  end

  Faraday::Request.register_middleware(guesty_rate_limiter: RateLimiterMiddleware)
end
