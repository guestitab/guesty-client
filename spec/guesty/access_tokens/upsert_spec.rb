RSpec.describe Guesty::AccessTokens::Upsert do
  subject(:result) { described_class.new.call }

  let(:store) { Guesty.config.token_store }

  context 'when an active token is stored' do
    it 'returns it without a request' do
      expect(result.value!.access_token).to eq('test-access-token')
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
    before { store.clear }

    it 'mints and stores a token' do
      expect(result.value!.access_token).to eq('<API_TOKEN>')
      expect(store.read('default_0')).not_to be_nil
    end
  end
end
