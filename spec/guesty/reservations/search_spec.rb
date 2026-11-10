RSpec.describe Guesty::Reservations::Search do
  include_context 'operations'

  let(:args) { { attributes:, skip: 0, take: } }
  let(:take) { 100 }
  let(:endpoint) { 'https://open-api.guesty.com/v1/reservations-v3/search' }
  let(:body) do
    {
      results: [
        {
          reservationId: '67acc90e908e2e0012d1207d',
          confirmationCode: 'HMYWKZA92Z',
          status: 'confirmed',
          guestId: '67acc90e6c81408ce5418909',
          checkInDateLocalized: '2026-07-01',
          checkOutDateLocalized: '2026-07-02',
          source: 'airbnb2',
          channel: 'airbnb2',
          createdAt: '2026-04-25T10:00:00.000Z',
          stay: [{ listingId: '67acc856c4410c00111a503d', checkInDateLocalized: '2026-07-01', checkOutDateLocalized: '2026-07-02', guestsCount: 2 }]
        }
      ],
      pagination: { skip: 0, limit: take, hasMore: false }
    }
  end

  context 'with valid arguments' do
    before do
      stub_request(:get, endpoint).with(query: query).to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })

      result
    end

    context 'with filter by confirmation_code' do
      let(:attributes) { { confirmation_code: 'HMYWKZA92Z' } }
      let(:query) { { 'filter' => { 'confirmationCode' => 'HMYWKZA92Z' }, 'sort' => 'createdAt', 'limit' => '100', 'skip' => '0' } }

      it_behaves_like 'successful call', value_containing: -> {
        {
          results: array_including(a_hash_including(reservationId: '67acc90e908e2e0012d1207d', status: 'confirmed')),
          pagination: { skip: 0, limit: 100, hasMore: false }
        }
      }

      it 'queries with the bracket filter, sort and pagination' do
        expect(WebMock).to have_requested(:get, endpoint).with(query:)
      end
    end

    context 'with several statuses' do
      let(:attributes) { { status: %w[confirmed reserved] } }
      let(:query) { hash_including('filter' => { 'status' => 'confirmed,reserved' }) }

      it 'joins the values into an implicit in' do
        expect(WebMock).to have_requested(:get, endpoint).with(query:)
      end
    end

    context 'with a check-in range' do
      let(:attributes) { { check_in: Date.new(2026, 1, 1)...Date.new(2026, 2, 1) } }
      let(:query) { hash_including('filter' => { 'checkIn' => { 'gte' => '2026-01-01', 'lt' => '2026-02-01' } }) }

      it_behaves_like 'successful call'

      it 'maps the range onto gte and lt operators' do
        expect(WebMock).to have_requested(:get, endpoint).with(query:)
      end
    end

    context 'with a created_at range' do
      let(:attributes) { { created_at: Time.utc(2026, 1, 1)..Time.utc(2026, 2, 1) } }
      let(:query) { hash_including('filter' => { 'createdAt' => { 'gte' => '2026-01-01T00:00:00Z', 'lte' => '2026-02-01T00:00:00Z' } }) }

      it 'maps the range onto ISO 8601 bounds' do
        expect(WebMock).to have_requested(:get, endpoint).with(query:)
      end
    end
  end

  context 'with invalid arguments' do
    before do
      allow(Guesty).to receive(:do_request)
      result
    end

    context 'when no attributes are given' do
      let(:attributes) { {} }
      let(:message) { 'attributes: required' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError

      it 'does not call Guesty' do
        expect(Guesty).not_to have_received(:do_request)
      end
    end

    context 'when a filter is unknown' do
      let(:attributes) { { updated_at: Date.new(2026, 1, 1) } }
      let(:message) { 'attributes: invalid' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end

    context 'when an identifier filter is blank' do
      let(:attributes) { { confirmation_code: '' } }
      let(:message) { 'confirmation_code: required' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end

    context 'when a range filter is not a range' do
      let(:attributes) { { check_in: Date.new(2026, 1, 1) } }
      let(:message) { 'check_in: invalid' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end

    context 'when the sort is unsupported' do
      let(:attributes) { { status: 'confirmed' } }
      let(:args) { { attributes:, sort: 'lastUpdatedAt' } }
      let(:message) { 'sort: invalid' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end
  end
end
