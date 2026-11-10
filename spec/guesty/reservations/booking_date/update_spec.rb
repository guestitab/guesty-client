RSpec.describe Guesty::Reservations::BookingDate::Update do
  include_context 'operations'

  let(:args) { { reservation_id: 'reservation-1', booking_date: Time.zone.local(2026, 5, 1, 12, 0, 0) } }
  let(:endpoint) { 'https://open-api.guesty.com/v1/reservations-v3/reservation-1/booking-date' }

  context 'with valid arguments' do
    before do
      stub_request(:put, endpoint).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      result
    end

    it_behaves_like 'successful call', value: true

    it 'puts the booking date in UTC' do
      expect(WebMock).to have_requested(:put, endpoint).with(body: { bookingDate: '2026-05-01T10:00:00.000Z' }).once
    end
  end

  context 'without a booking date' do
    let(:args) { { reservation_id: 'reservation-1', booking_date: nil } }
    let(:message) { 'booking_date: required' }

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
  end
end
