RSpec.describe Guesty::Homes::Calendars::Show do
  include_context 'operations'

  let(:args) { { home_id:, start_date:, end_date: } }

  let(:home_id) { '67ee2ce21ce3a2001334966b' }
  let(:start_date) { Date.new(2026, 8, 16) }
  let(:end_date) { Date.new(2026, 8, 31) }

  context 'with valid arguments', vcr: { cassette_name: 'homes/calendars/show' } do
    it_behaves_like 'successful call', value_containing: -> {
      {
        available: array_including(
          { date: '2026-08-18', price: 0, min_nights: 1, check_in: false },
          { date: '2026-08-21', price: 0, min_nights: 1, check_in: true }
        ),
        unavailable: eq(
          [
            { date: '2026-08-19', price: 0, min_nights: 1, check_in: false, blocked_as: %i[manual_block booked_reservation] },
            { date: '2026-08-20', price: 0, min_nights: 1, check_in: false, blocked_as: [:manual_block] },
            { date: '2026-08-30', price: 0, min_nights: 1, check_in: false, blocked_as: [:manual_block] },
            { date: '2026-08-31', price: 0, min_nights: 1, check_in: false, blocked_as: [:manual_block] }
          ]
        ),
        blocks: contain_exactly({
                                  kind: :booked_reservation,
                                  start_date: Date.new(2026, 8, 18),
                                  end_date: Date.new(2026, 8, 18),
                                  comment: nil
                                }, {
                                  kind: :booked_reservation,
                                  start_date: Date.new(2026, 8, 19),
                                  end_date: Date.new(2026, 8, 19),
                                  comment: nil
                                }, {
                                  kind: :manual_block,
                                  start_date: Date.new(2026, 8, 19),
                                  end_date: Date.new(2026, 8, 20),
                                  comment: 'OOO'
                                }, {
                                  kind: :manual_block,
                                  start_date: Date.new(2026, 8, 30),
                                  end_date: Date.new(2026, 9, 2),
                                  comment: 'Owner block via guesty'
                                })
      }
    }
  end

  context 'when a reservation checks in on the day another one checks out',
          vcr: { cassette_name: 'homes/calendars/show/back_to_back_reservations' } do
    let(:home_id) { '67ee2b0e25977e0019b9e459' }
    let(:start_date) { Date.new(2027, 1, 16) }
    let(:end_date) { Date.new(2027, 1, 24) }

    it_behaves_like 'successful call', value_containing: -> {
      {
        available: match(
          [
            a_hash_including(date: '2027-01-16', check_in: true),
            a_hash_including(date: '2027-01-17', check_in: true),
            a_hash_including(date: '2027-01-18', check_in: false),
            a_hash_including(date: '2027-01-22', check_in: true),
            a_hash_including(date: '2027-01-23', check_in: true),
            a_hash_including(date: '2027-01-24', check_in: true)
          ]
        ),
        unavailable: eq(
          [
            { date: '2027-01-19', price: 0, min_nights: 1, check_in: false, blocked_as: [:booked_reservation] },
            { date: '2027-01-20', price: 0, min_nights: 1, check_in: false, blocked_as: [:booked_reservation] },
            { date: '2027-01-21', price: 0, min_nights: 1, check_in: false, blocked_as: [:booked_reservation] }
          ]
        ),
        blocks: contain_exactly(
          { kind: :booked_reservation, start_date: Date.new(2027, 1, 18), end_date: Date.new(2027, 1, 19), comment: nil },
          { kind: :booked_reservation, start_date: Date.new(2027, 1, 20), end_date: Date.new(2027, 1, 21), comment: nil }
        )
      }
    }
  end

  context 'when every day is blocked in another currency' do
    let(:endpoint) { "https://open-api.guesty.com/v1/availability-pricing/api/calendar/listings/minified/#{home_id}" }
    let(:days) do
      {
        listingId: home_id,
        currency: 'EUR',
        calendar: [
          { date: '2026-08-16', price: 120, minNights: 1, blocks: { m: true }, blockIds: ['block'] },
          { date: '2026-08-17', price: 120, minNights: 1, blocks: { m: true }, blockIds: ['block'] }
        ],
        blocks: { block: { type: 'm', startDate: '2026-08-16T00:00:00.000Z', endDate: '2026-08-17T00:00:00.000Z' } }
      }
    end
    let(:message) { 'unsupported currency EUR' }

    before do
      stub_request(:get, endpoint)
        .with(query: { startDate: start_date.to_s, endDate: end_date.to_s, view: 'full' })
        .to_return(status: 200, body: { status: 200, data: { days: } }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it_behaves_like 'failed call'
  end

  context 'with invalid arguments' do
    context 'when the end_date is not after the start_date' do
      let(:end_date) { start_date }
      let(:message) { 'end_date: invalid' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end
  end
end
