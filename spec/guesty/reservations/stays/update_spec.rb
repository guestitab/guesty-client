RSpec.describe Guesty::Reservations::Stays::Update do
  include_context 'operations'

  let(:args) { { reservation_id: 'reservation-1', stay: } }

  let(:stay) do
    {
      start_date: Date.new(2026, 11, 3),
      end_date: Date.new(2026, 11, 7),
      check_in: Time.utc(2026, 1, 1, 16, 0),
      check_out: Time.utc(2026, 1, 1, 10, 0),
      num_guests: 3,
      adults: 2,
      children: 1,
      ignore_calendar: true,
      listing_external_id: 'listing-1'
    }
  end
  let(:body) do
    {
      checkInDateLocalized: '2026-11-03',
      checkOutDateLocalized: '2026-11-07',
      plannedArrival: '16:00',
      plannedDeparture: '10:00',
      guestsCount: 3,
      numberOfGuests: { numberOfAdults: 2, numberOfChildren: 1 },
      ignoreCalendar: true,
      ignoreTerms: true,
      listingId: 'listing-1'
    }
  end

  before do
    stub_request(:put, 'https://open-api.guesty.com/v1/reservations/reservation-1')
      .with(body:)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    result
  end

  it_behaves_like 'successful call', value: true
end
