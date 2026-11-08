module Guesty
  # A rejected Guesty response. Carries the response and its parsed body, and
  # classifies transience so callers can tell a retryable glitch from a write
  # that never landed (see Guesty.unapplied? and Guesty.delivery_unknown?).
  class ApiError < Error
    GLITCH_MESSAGES = [
      /An invalid response was received from the upstream server/,
      /Forbidden err/,
      /Reservation Meta not found/,
      /Write conflict during plan execution/,
      /You don't have permission to access, please contact Guesty support/
    ].freeze

    RETRYABLE_NON_DELIVERY_STATUSES = [401, 403, 429].freeze #: ::Array[::Integer]
    PERMANENT_REJECTION_STATUSES = [400, 404, 405, 409, 410, 415, 422].freeze #: ::Array[::Integer]
    UPSTREAM_STATUS = /\ARequest failed with status code (\d{3})\z/ #: ::Regexp

    attr_reader :raw_body, :response

    # @rbs (Faraday::Response response) -> void
    def initialize(response)
      @response = response
      @raw_body = response.body

      super(error_message.to_s.presence || response.status.to_s)
    end

    # @rbs () -> Integer
    def status
      body_status = @raw_body[:status] if @raw_body.is_a?(Hash)
      parsed_status = Integer(body_status, exception: false) || Integer(error_message.to_s[UPSTREAM_STATUS, 1], exception: false)

      parsed_status && parsed_status >= 300 ? parsed_status : @response.status
    end

    def guesty_glitch?
      GLITCH_MESSAGES.any? do |message|
        error_message.to_s =~ message
      end
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

      error_paths = [%i[error data], %i[error message], :message, :data, :error, :code]

      error_message = error_paths.find do |path|
        value = path.is_a?(Array) ? @raw_body.dig(*path) : @raw_body[path]
        break value if value.present?
      end

      error_message.is_a?(Array) ? error_message.join(', ') : error_message || @raw_body
    end
  end
end
