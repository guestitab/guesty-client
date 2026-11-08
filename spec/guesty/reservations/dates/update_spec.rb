RSpec.describe Guesty::Reservations::Dates::Update do
  include_context 'operations'

  let(:args) { { reservation_id: '6994428d8c8b777629832246', attributes: } }

  let(:attributes) do
    {
      start_date: Date.new(2026, 6, 10),
      end_date: Date.new(2026, 6, 11)
    }
  end

  context 'with valid arguments', vcr: { cassette_name: 'reservations/dates/update' } do
    it_behaves_like 'successful call', value: true
  end

  context 'with planned times and constraint flags' do
    let(:ignore_constraints) { true }
    let(:attributes) do
      super().merge(
        check_in: Time.utc(2026, 1, 1, 16, 0),
        check_out: Time.utc(2026, 1, 1, 10, 0),
        ignore_calendar: ignore_constraints,
        ignore_terms: ignore_constraints
      )
    end
    let(:wire_attributes) do
      {
        checkInDateLocalized: '2026-06-10',
        checkOutDateLocalized: '2026-06-11',
        plannedArrival: '16:00',
        plannedDeparture: '10:00',
        ignoreCalendar: ignore_constraints,
        ignoreTerms: ignore_constraints,
        applyRecalculation: false
      }
    end

    before do
      stub_request(:put, 'https://open-api.guesty.com/v1/reservations-v3/6994428d8c8b777629832246/dates')
        .with(body: wire_attributes)
        .to_return(status: 200)
    end

    it_behaves_like 'successful call', value: true

    context 'when constraint checks are kept' do
      let(:ignore_constraints) { false }

      it_behaves_like 'successful call', value: true
    end
  end
end
