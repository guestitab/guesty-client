RSpec.describe Guesty::Reservations::Index do
  subject(:result) { described_class.new.call(**args) }

  let(:args) { { reservation_ids: } }
  let(:reservation_ids) { %w[6835c385fe621d0026ce5511 67acc90e908e2e0012d1207d] }
  let(:endpoint) { 'https://open-api.guesty.com/v1/reservations-v3' }

  context 'with valid arguments' do
    before do
      stub_request(:get, endpoint)
        .with(query: { reservationIds: reservation_ids })
        .to_return(
          status: 200,
          body: [{ _id: reservation_ids.first, status: 'confirmed' }, { _id: reservation_ids.last, status: 'canceled' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the reservations' do
      expect(result.value!).to eq([{ _id: reservation_ids.first, status: 'confirmed' }, { _id: reservation_ids.last, status: 'canceled' }])
    end
  end

  context 'without ids' do
    let(:reservation_ids) { [] }
    let(:message) { 'reservation_ids: required' }

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
  end

  context 'with more ids than one request allows' do
    let(:reservation_ids) { Array.new(11) { |index| "reservation-#{index}" } }
    let(:message) { 'reservation_ids: invalid' }

    before do
      allow(Guesty).to receive(:do_request)
      result
    end

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError

    it 'does not call Guesty' do
      expect(Guesty).not_to have_received(:do_request)
    end
  end
end
