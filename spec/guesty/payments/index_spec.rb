RSpec.describe Guesty::Payments::Index do
  subject(:result) { described_class.new.call(**args) }

  let(:args) { { reservation_id: } }
  let(:reservation_id) { '67ebc9c7c5904c0010502f89' }
  let(:endpoint) { 'https://open-api.guesty.com/v1/payments' }
  let(:summary) do
    {
      payments: [{ _id: '64da25d683ad1500284bd0ef', reservationId: reservation_id, status: 'SUCCEEDED', amount: 4379.62, note: 'Paid' }],
      balanceDue: 0,
      paymentsDue: 0,
      totalPaid: 4379.62,
      totalRefunded: 0,
      isFullyPaid: true,
      isTouchedPayments: true,
      currency: 'SEK',
      hostPayout: 4379.62
    }
  end

  context 'with a known reservation' do
    before do
      stub_request(:get, endpoint)
        .with(query: { reservationId: reservation_id })
        .to_return(status: 200, body: summary.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the payments and summary fields' do
      expect(result.value!).to eq(summary)
    end
  end

  context 'without a reservation id' do
    let(:reservation_id) { '' }
    let(:message) { 'reservation_id: required' }

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
  end
end
