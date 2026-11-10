RSpec.describe Guesty::Reservations::Recover do
  subject(:result) { described_class.new.call(**args) }

  let(:args) { { confirmation_code: 'HMYWKZA92Z', start_date: Date.new(2026, 7, 1), end_date: Date.new(2026, 7, 2) } }
  let(:endpoint) { 'https://open-api.guesty.com/v1/reservations-v3/search' }
  let(:matching) do
    {
      reservationId: '67acc90e908e2e0012d1207d',
      confirmationCode: 'HMYWKZA92Z',
      status: 'confirmed',
      checkInDateLocalized: '2026-07-01',
      checkOutDateLocalized: '2026-07-02'
    }
  end
  let(:results) { [matching] }

  before do
    stub_request(:get, endpoint)
      .with(query: hash_including('filter' => { 'confirmationCode' => 'HMYWKZA92Z' }))
      .to_return(status: 200, body: { results:, pagination: { skip: 0, limit: 2, hasMore: false } }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'returns the reservation id' do
    expect(result.value!).to eq('67acc90e908e2e0012d1207d')
  end

  context 'when the match is canceled' do
    let(:matching) { super().merge(status: 'canceled') }

    it 'returns nil' do
      expect(result.value!).to be_nil
    end
  end

  context 'when the stay window differs' do
    let(:matching) { super().merge(checkOutDateLocalized: '2026-07-03') }

    it 'returns nil' do
      expect(result.value!).to be_nil
    end
  end
end
