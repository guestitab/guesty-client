module Guesty
  # The default rate limiter: in-memory fixed windows per key. Per-process only;
  # a host running several processes injects a shared backend (the core app
  # delegates to Prop on its cache) via Guesty.config.rate_limiter.
  class MemoryRateLimiter
    def initialize
      @windows = {}
    end

    # @rbs (key: ::Symbol, threshold: ::Integer, interval: untyped) -> void
    def throttle!(key:, threshold:, interval:)
      now = Time.now
      window_start, count = @windows.fetch(key, [now, 0])

      if now >= window_start + interval
        window_start = now
        count = 0
      end

      count += 1
      @windows[key] = [window_start, count]

      return if count <= threshold

      raise ThrottledError.new(key:, threshold:, interval:, retry_after: (window_start + interval) - now)
    end
  end
end
