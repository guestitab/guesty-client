RSpec.describe Guesty::Reservations::Guests::Update do
  include_context 'operations'

  let(:args) { { reservation_id: 'reservation-1', attributes: } }
  let(:attributes) do
    {
      num_guests: 3,
      adults: 2,
      children: 1,
      ignore_calendar: true,
      ignore_terms: true
    }
  end
  let(:endpoint) { 'https://open-api.guesty.com/v1/reservations-v3/reservation-1/guests' }

  context 'with valid arguments' do
    before do
      stub_request(:put, endpoint).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      result
    end

    it_behaves_like 'successful call', value: true

    it 'puts the guests breakdown' do
      expect(WebMock).to have_requested(:put, endpoint).with(
        body: {
          guestsCount: 3,
          numberOfGuests: { numberOfAdults: 2, numberOfChildren: 1 },
          ignoreCalendar: true,
          ignoreTerms: true
        }
      ).once
    end
  end

  context 'without a guest count' do
    let(:attributes) { { adults: 2 } }
    let(:message) { 'num_guests: required' }

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
  end
end
