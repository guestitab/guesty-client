RSpec.describe Guesty::Webhooks::Signatures::Verify do
  include_context 'operations'

  let(:args) { { payload:, headers: } }

  let(:now) { Time.zone.at(1_614_265_330) }
  let(:payload) { '{"test": 2432232314}' }
  let(:headers) do
    {
      'svix-id' => 'msg_p5jXN8AQM9LWM0D4loKWxJek',
      'svix-timestamp' => now.to_i.to_s,
      'svix-signature' => signature
    }
  end
  let(:signature) { 'v1,g0hM9SsE+OTPJTGt/tmIKtSyZlE3uFJELVlNIOLJ1OE=' }
  let(:webhook_key) { 'whsec_MfKQ9r8GKYqrTwjUPD8ILPZIo2LaLaSw' }

  before do
    travel_to(now)
    allow(Guesty).to receive(:webhook_key).and_return(webhook_key)
  end

  context 'with valid arguments' do
    it_behaves_like 'successful call', value: true

    context 'without a svix header' do
      let(:headers) { super().except('svix-signature') }
      let(:message) { 'Missing Svix headers' }

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end

    context 'when the timestamp is stale' do
      let(:message) { 'Svix timestamp is outside the tolerance' }

      before { travel 6.minutes }

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end

    context 'when the timestamp is ahead of the clock' do
      let(:message) { 'Svix timestamp is outside the tolerance' }

      before { travel(-6.minutes) }

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end

    context 'when the webhook key is not configured' do
      let(:webhook_key) { nil }
      let(:message) { 'Guesty webhook signing key is not configured' }

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end

    context 'when the payload does not match the signature' do
      let(:payload) { '{"test": 1}' }
      let(:message) { 'No matching Svix signature' }

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end

    context 'when the signature carries an unknown version' do
      let(:signature) { 'v2,g0hM9SsE+OTPJTGt/tmIKtSyZlE3uFJELVlNIOLJ1OE=' }
      let(:message) { 'No matching Svix signature' }

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end
  end
end
