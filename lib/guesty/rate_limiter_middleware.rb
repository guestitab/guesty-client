module Guesty
  class RateLimiterMiddleware < Faraday::Middleware
    # @rbs (untyped env) -> void
    def on_request(_env)
      Guesty.config.rate_limiter.throttle!(key: options[:key].call, threshold: options[:threshold], interval: options[:interval])
    end
  end

  Faraday::Request.register_middleware(guesty_rate_limiter: RateLimiterMiddleware)
end
