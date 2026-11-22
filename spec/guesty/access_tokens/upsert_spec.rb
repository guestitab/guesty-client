RSpec.describe Guesty::AccessTokens::Upsert do
  subject(:result) { described_class.new.call }

  let(:store) { Guesty.config.token_store }
  let(:mint_stub) { stub_request(:post, described_class::OAUTH_ENDPOINT) }

  context 'when an active token is stored' do
    it 'returns it without a request' do
      expect(result.value!.access_token).to eq('test-access-token')
      expect(mint_stub).not_to have_been_requested
    end
  end

  context 'when the stored token is expired', vcr: { cassette_name: 'access_tokens/upsert' } do
    before { store.save(slot_key: 'default_0', access_token: 'expired-token', expires_at: Time.now - 3600) }

    it 'mints a token and replaces the stored one' do
      expect(result.value!.access_token).to eq('<API_TOKEN>')
      expect(store.read('default_0').access_token).to eq('<API_TOKEN>')
    end
  end

  context 'when no token is stored', vcr: { cassette_name: 'access_tokens/upsert' } do
    before { Guesty.config.token_store = Guesty::MemoryTokenStore.new }

    it 'mints and stores a token' do
      expect(result.value!.access_token).to eq('<API_TOKEN>')
      expect(store.read('default_0')).not_to be_nil
    end
  end

  context 'when the stored token expires within the refresh window' do
    before do
      store.save(slot_key: 'default_0', access_token: 'aging-token', expires_at: Time.now + 600)
      mint_stub.to_return(status: 502, body: '{}')
    end

    it 'keeps the stored token when the mint fails' do
      expect(result.value!.access_token).to eq('aging-token')
      expect(mint_stub).to have_been_requested.once
    end
  end

  context 'when no token is stored and the mint fails' do
    before do
      Guesty.config.token_store = Guesty::MemoryTokenStore.new
      mint_stub.to_return(status: 502, body: '{}')
    end

    it 'raises, and a second call within the interval is throttled without a request' do
      expect { described_class.new.call! }.to raise_error(Guesty::ApiError)
      expect { described_class.new.call! }.to raise_error(Guesty::ThrottledError)
      expect(mint_stub).to have_been_requested.once
    end

    context 'when another slot holds a valid token' do
      before { store.save(slot_key: 'high', access_token: 'high-token', expires_at: Time.now + 3600) }

      it 'borrows it without saving it under the dead slot' do
        expect(result.value!.access_token).to eq('high-token')
        expect(store.read('default_0')).to be_nil
      end
    end
  end
end
