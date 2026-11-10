RSpec.describe Guesty::Reservations::Show do
  subject(:result) { described_class.new.call(**args) }

  let(:args) { { reservation_id: } }
  let(:reservation_id) { '6835c385fe621d0026ce5511' }
  let(:endpoint) { 'https://open-api.guesty.com/v1/reservations-v3' }
  let(:reservation) do
    {
      _id: reservation_id,
      status: 'confirmed',
      bookerId: '6835c3847572b11a7e7e6eef',
      platform: 'airbnb2',
      conversationId: '6835c385d51239149deb8b99',
      moneyId: '6835c38527bdd20999c250d5',
      stay: [
        {
          unitTypeId: '67e1c7c2a7bd17007449b163',
          unitId: '67e1c7c2a7bd17007449b163',
          checkInDateLocalized: '2026-06-01',
          checkOutDateLocalized: '2026-06-02',
          guestsCount: 2,
          numberOfGuests: { numberOfAdults: 2, numberOfChildren: 0 }
        }
      ]
    }
  end

  context 'with a known reservation' do
    before do
      stub_request(:get, endpoint)
        .with(query: { reservationIds: [reservation_id] })
        .to_return(status: 200, body: [reservation].to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the reservation attributes' do
      expect(result.value!).to eq(reservation)
    end
  end

  context 'when the reservation does not exist' do
    let(:message) { "Reservation #{reservation_id} not found on Guesty" }
    let(:fatal) { true }

    before do
      stub_request(:get, endpoint)
        .with(query: { reservationIds: [reservation_id] })
        .to_return(status: 200, body: [].to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it_behaves_like 'failed call', failure_class: Guesty::Error
  end

  context 'without a reservation id' do
    let(:reservation_id) { '' }
    let(:message) { 'reservation_id: required' }

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
  end
end
