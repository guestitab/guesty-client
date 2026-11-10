module Guesty
  class ApiError < Error
    GLITCH_MESSAGES = Regexp.union(
      /An invalid response was received from the upstream server/,
      /Forbidden err/,
      /Reservation Meta not found/,
      /Write conflict during plan execution/,
      /You don't have permission to access, please contact Guesty support/
    ) #: ::Regexp

    RETRYABLE_NON_DELIVERY_STATUSES = [401, 403, 429].freeze #: ::Array[::Integer]
    PERMANENT_REJECTION_STATUSES = [400, 404, 405, 409, 410, 415, 422].freeze #: ::Array[::Integer]
    UPSTREAM_STATUS = /\ARequest failed with status code (\d{3})\z/ #: ::Regexp
    ERROR_PATHS = [%i[error data], %i[error message], [:message], [:data], [:error], [:code]].freeze #: ::Array[::Array[::Symbol]]

    attr_reader :raw_body, :response

    # @rbs (Faraday::Response response) -> void
    def initialize(response)
      @response = response
      @raw_body = response.body

      super(error_message.to_s.presence || response.status.to_s)
    end

    # Guesty tunnels errors through HTTP 200 bodies and relays upstream ones in the message.
    # @rbs () -> Integer
    def status
      body_status = @raw_body[:status] if @raw_body.is_a?(Hash)
      parsed_status = Integer(body_status, exception: false) || Integer(message[UPSTREAM_STATUS, 1], exception: false)

      parsed_status && parsed_status >= 300 ? parsed_status : @response.status
    end

    # @rbs () -> bool
    def guesty_glitch?
      GLITCH_MESSAGES.match?(message)
    end

    # @rbs () -> bool
    def retryable_non_delivery?
      RETRYABLE_NON_DELIVERY_STATUSES.include?(status)
    end

    # @rbs () -> bool
    def permanent_rejection?
      PERMANENT_REJECTION_STATUSES.include?(status)
    end

    # @rbs () -> bool
    def transient?
      retryable_non_delivery? || guesty_glitch? || status == 408 || status >= 500
    end

    private

    # @rbs () -> untyped
    def error_message
      return @raw_body unless @raw_body.respond_to?(:dig)

      error_message = ERROR_PATHS.lazy.map { |path| @raw_body.dig(*path) }.find(&:present?)
      error_message.is_a?(Array) ? error_message.join(', ') : error_message || @raw_body
    end
  end
end
