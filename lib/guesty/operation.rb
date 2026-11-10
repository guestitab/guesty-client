module Guesty
  module Operation
    def self.included(base)
      base.include Dry::Monads[:result]
      base.prepend(Call)
    end

    module Call
      def call(*, **, &)
        super
      rescue StandardError => e
        Failure(e)
      end
    end

    def call!(...)
      result = call(...)
      raise result.failure if result.failure?

      result
    end

    private

    # @rbs (::Symbol request_method, ::String path, ?::Hash[::Symbol, untyped] params, ?retries: ::Integer, ?timeout: ::Integer) -> untyped
    def request(...)
      Guesty.do_request(...).value_or { |error| raise error }.body
    end

    def argument!(fatal: false, **attrs)
      key, reason = attrs.first
      raise Guesty::ArgumentError.new("#{key}: #{reason}", fatal:)
    end

    def error!(message, fatal: false)
      raise Guesty::Error.new(message, fatal:)
    end
  end
end
