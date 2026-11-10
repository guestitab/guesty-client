module Guesty
  extend Dry::Monads::Result::Mixin

  BASE_URL = 'https://open-api.guesty.com/v1/'.freeze #: ::String
  TIMEOUT = 20 #: ::Integer

  RETRY_OPTIONS = {
    max: 50,
    interval: 1.0,
    interval_randomness: 0.5,
    backoff_factor: 1,
    retry_statuses: [429],
    exceptions: [*Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS, Faraday::ConnectionFailed],
    methods: [*Faraday::Retry::Middleware::IDEMPOTENT_METHODS, :patch]
  }.freeze #: ::Hash[::Symbol, untyped]

  # @rbs (?url: ::String, ?skip_auth: bool, ?timeout: ::Integer) -> Faraday::Connection
  def self.connection(url: config.base_url, skip_auth: false, timeout: TIMEOUT)
    Faraday.new(url:) do |builder|
      builder.request :authorization, 'Bearer', -> { auth_token } unless skip_auth

      builder.request :json
      builder.request :retry, RETRY_OPTIONS

      builder.request :guesty_rate_limiter, threshold: 10, interval: 1.second, key: -> { rate_limit_key(:second) }
      builder.request :guesty_rate_limiter, threshold: 120, interval: 1.minute, key: -> { rate_limit_key(:minute) }
      builder.request :guesty_rate_limiter, threshold: 5000, interval: 1.hour, key: -> { rate_limit_key(:hour) }

      builder.request :url_encoded
      builder.response :json, parser_options: { symbolize_names: true, mode: :rails, decoder: [Oj, :load] }
      builder.options[:timeout] = timeout
    end
  end

  # @rbs (::Symbol | ::String request_method, ::String path, ?::Hash[::Symbol, untyped] params, ?retries: ::Integer, ?timeout: ::Integer) -> untyped
  def self.do_request(request_method, path, params = {}, retries: 3, timeout: TIMEOUT)
    Fiber[:guesty__slot] = pick_slot(current_priority)

    http = connection(timeout:)
    response = params.present? ? http.public_send(request_method, path, params) : http.public_send(request_method, path)
    return Success(response) if successful_response?(response)

    error = ApiError.new(response)
    return Failure(error) unless retries.positive? && error.guesty_glitch?

    sleep(1.0)
    do_request(request_method, path, params, retries: retries - 1, timeout:)
  end

  # @rbs (::Symbol priority) { (?) -> untyped } -> untyped
  def self.with_priority(priority, &block)
    previous_priority = current_priority
    Fiber[:guesty__priority] = priority
    block.call
  ensure
    Fiber[:guesty__priority] = previous_priority
  end

  # @rbs () -> ::Symbol
  def self.current_priority
    Fiber[:guesty__priority] || :default
  end

  # @rbs () -> slot
  def self.current_slot
    Fiber[:guesty__slot] || token_slots(current_priority).first
  end

  # @rbs (::Symbol window) -> ::Symbol
  def self.rate_limit_key(window)
    :"guesty_http_limit_#{window}_#{current_slot[:key]}"
  end

  # @rbs (?::Symbol priority) -> ::Array[slot]
  def self.token_slots(priority = current_priority)
    creds = Array.wrap(config.credentials[priority])

    creds.each_with_index.map do |cred, index|
      key = creds.one? ? priority.to_s : "#{priority}_#{index}"

      {
        key:,
        client_id: cred[:client_id],
        secret: cred[:secret]
      }
    end
  end

  # @rbs () -> ::String?
  def self.webhook_key
    config.credentials[:webhook_key]
  end

  # @rbs () -> bool
  def self.sync_guest_and_reservation_changes?
    !!config.sync_guest_and_reservation_changes
  end

  # @rbs (::Symbol priority) -> slot
  def self.pick_slot(priority)
    slots = token_slots(priority)
    return slots.fetch(0) if slots.one?

    config.slot_picker.call(slots, priority)
  end

  # @rbs (Faraday::Response response) -> bool
  def self.successful_response?(response)
    return false unless response.success?

    !response.body.is_a?(Hash) || response.body[:status].blank? || response.body[:status].to_i < 300
  end

  # @rbs (::StandardError error) -> bool
  def self.retryable_read?(error)
    return true if error.is_a?(Faraday::TimeoutError) || error.is_a?(Faraday::ConnectionFailed)

    error.is_a?(ApiError) && error.transient?
  end

  # @rbs (::StandardError error) -> bool
  def self.unapplied?(error)
    return true if error.is_a?(Guesty::ThrottledError)

    error.is_a?(ApiError) && (error.retryable_non_delivery? || error.permanent_rejection?)
  end

  # @rbs (::StandardError error) -> bool
  def self.delivery_unknown?(error)
    (error.is_a?(ApiError) || error.is_a?(Faraday::Error)) && !unapplied?(error)
  end

  # @rbs () -> ::String
  def self.auth_token
    AccessTokens::Upsert.new.call!.value!.access_token
  end
end
