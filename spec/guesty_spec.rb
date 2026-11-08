RSpec.describe Guesty do
  def api_error(status, message: 'Nope')
    Guesty::ApiError.new(instance_double(Faraday::Response, status:, body: { error: { message: } }))
  end

  describe '::RETRY_OPTIONS' do
    it 'leaves local rate limits to operation-level retry handling' do
      expect(described_class::RETRY_OPTIONS[:exceptions]).not_to include(Guesty::ThrottledError)
    end
  end

  describe '.do_request' do
    subject(:response) { described_class.do_request(request_method, path, params, retries:) }

    let(:request_method) { :post }
    let(:path) { 'reservations-v3/reservation/approve' }
    let(:params) { {} }
    let(:retries) { 3 }
    let(:endpoint) { "#{described_class::BASE_URL}#{path}" }

    context 'when Guesty refuses the request', vcr: { cassette_name: 'conversations/attachments/index/not_found' } do
      let(:request_method) { :get }
      let(:path) { 'communication/conversations/get-attachments' }
      let(:params) { { keys: ['production/67853b83eab5de1fd4c47333/jpeg/60a5fa8262e3a0fea0e6e42528a22ce6_broken-window.jpeg'] } }

      it 'fails with the status and message Guesty answered' do
        expect(response.failure).to be_a(described_class::ApiError).and have_attributes(status: 404, message: 'Attachments not found')
      end
    end

    context 'when Guesty answers 200 with an error status' do
      before do
        stub_request(:post, endpoint)
          .to_return(status: 200, body: { status: '429', error: { message: 'Rate limit exceeded' } }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'fails with the tunnelled status' do
        expect(response.failure).to have_attributes(status: 429, message: 'Rate limit exceeded')
      end
    end

    context 'when Guesty glitches once' do
      let(:glitch) { { status: 500, body: { error: { message: 'Write conflict during plan execution' } }.to_json, headers: { 'Content-Type' => 'application/json' } } }

      before do
        allow(described_class).to receive(:sleep)
        stub_request(:post, endpoint).to_return(glitch, { status: 201, body: '' })
      end

      it 'retries the request' do
        expect(response).to be_success_monad
        expect(WebMock).to have_requested(:post, endpoint).twice
      end

      context 'with retries: 0' do
        let(:retries) { 0 }

        it 'sends the request once' do
          expect(response.failure).to be_guesty_glitch
          expect(WebMock).to have_requested(:post, endpoint).once
        end
      end
    end
  end

  describe '.with_priority' do
    before do
      # do_request leaves its picked slot on the fiber; this describe pins the priority lane.
      Fiber[:guesty__slot] = nil
      described_class.config.token_store.save(slot_key: 'high', access_token: 'high-access-token', expires_at: Time.now + 3600)
    end

    it 'authenticates with the first token of the priority' do
      expect(described_class.with_priority(:high) { described_class.auth_token }).to eq('high-access-token')
    end

    it 'restores the previous priority' do
      expect { described_class.with_priority(:high) { nil } }.not_to change(described_class, :auth_token).from('test-access-token')
    end

    context 'when the default minute limit is used up' do
      let(:path) { 'availability-pricing/api/calendar/listings/minified/67ee2ce21ce3a2001334966b' }
      let(:params) { { startDate: Date.new(2026, 8, 16), endDate: Date.new(2026, 8, 31), view: 'full' } }

      before do
        stub_request(:get, /availability-pricing/).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

        key = described_class.rate_limit_key(:minute)
        120.times { described_class.config.rate_limiter.throttle!(key:, threshold: 120, interval: 1.minute) }
      end

      it 'keeps a separate limit per priority' do
        expect(described_class.with_priority(:high) { described_class.do_request(:get, path, params) }).to be_success_monad
        expect { described_class.do_request(:get, path, params) }.to raise_error(Guesty::ThrottledError, /guesty_http_limit_minute_default_0/)
      end
    end
  end

  describe '.token_slots' do
    subject(:slots) { described_class.token_slots(:high) }

    context 'with a single credentials hash' do
      before { described_class.configure { |guesty| guesty.credentials = { high: { client_id: 'cid', secret: 'sec' } } } }

      it 'returns one slot keyed by the bare priority name' do
        expect(slots).to eq([{ key: 'high', client_id: 'cid', secret: 'sec' }])
      end
    end

    context 'with an array of credentials' do
      before { described_class.configure { |guesty| guesty.credentials = { high: [{ client_id: 'a', secret: 'sa' }, { client_id: 'b', secret: 'sb' }] } } }

      it 'returns one indexed slot per credential' do
        expect(slots).to eq(
          [
            { key: 'high_0', client_id: 'a', secret: 'sa' },
            { key: 'high_1', client_id: 'b', secret: 'sb' }
          ]
        )
      end
    end
  end

  describe '.pick_slot' do
    before do
      counter = 0

      described_class.configure do |guesty|
        guesty.credentials = { high: [{ client_id: 'a', secret: 'sa' }, { client_id: 'b', secret: 'sb' }] }
        guesty.slot_picker = ->(slots, _priority) { slots.fetch((counter += 1) % slots.size) }
      end
    end

    it 'round-robins evenly across the pool via the injected picker' do
      expect(Array.new(4) { described_class.pick_slot(:high)[:key] }).to eq(%w[high_1 high_0 high_1 high_0])
    end
  end

  describe '.unapplied?' do
    it 'holds for failures that prove the write never took and leaves open whether a server error, a timeout or a lost connection landed' do
      expect(described_class.unapplied?(api_error(400))).to be(true)
      expect(described_class.unapplied?(api_error(429))).to be(true)
      expect(described_class.unapplied?(Guesty::ThrottledError.new(key: :guesty_limit, threshold: 120, interval: 60, retry_after: 30))).to be(true)
      expect(described_class.unapplied?(api_error(500))).to be(false)
      expect(described_class.unapplied?(Faraday::TimeoutError.new)).to be(false)
      expect(described_class.unapplied?(Faraday::ConnectionFailed.new)).to be(false)
    end
  end

  describe '.retryable_read?' do
    it 'retries authentication, rate limits, request timeouts and server errors' do
      [401, 403, 408, 429, 500, 503].each do |status|
        expect(described_class.retryable_read?(api_error(status))).to be(true)
      end
    end

    it 'retries transport failures' do
      [Faraday::TimeoutError, Faraday::ConnectionFailed].each do |error_class|
        expect(described_class.retryable_read?(error_class.new)).to be(true)
      end
    end

    it 'refuses permanent rejections and local errors' do
      [400, 404, 422].each do |status|
        expect(described_class.retryable_read?(api_error(status))).to be(false)
      end
      expect(described_class.retryable_read?(Guesty::ArgumentError.new('Home is not synced with Guesty'))).to be(false)
    end

    context 'when Guesty sends a known glitch with a permanent status' do
      let(:error) { api_error(400, message: 'Reservation Meta not found') }

      it 'retries the lookup' do
        expect(described_class.retryable_read?(error)).to be(true)
      end
    end
  end

  describe '.delivery_unknown?' do
    it 'holds for a server error or a timeout and not for a rejection or a failure before the request' do
      expect(described_class.delivery_unknown?(api_error(500))).to be(true)
      expect(described_class.delivery_unknown?(Faraday::TimeoutError.new)).to be(true)
      expect(described_class.delivery_unknown?(api_error(400))).to be(false)
      expect(described_class.delivery_unknown?(Guesty::ArgumentError.new('Home is not synced with Guesty'))).to be(false)
    end
  end
end
