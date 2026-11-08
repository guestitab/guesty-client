RSpec.describe Guesty::Reservations::Search do
  include_context 'operations'

  let(:args) { { fields:, attributes:, skip: 0, take: } }

  let(:fields) { %w[_id listing._id conversationId] }
  let(:take) { 2 }

  context 'with valid arguments' do
    context 'with filter by updated_at', vcr: { cassette_name: 'reservations/search/by_updated_at' } do
      let(:attributes) { { status: 'confirmed', updated_at: Date.new(2025, 4, 25) } }

      it_behaves_like 'successful call', value_containing: -> {
        {
          results: array_including(
            {
              _id: '67acc90e908e2e0012d1207d',
              integration: {
                platform: 'airbnb2',
                _id: '67acc6323649273a904219d2',
                limitations: {
                  availableStatuses: []
                }
              },
              listingId: '67acc856c4410c00111a503d',
              listing: { _id: '67acc856c4410c00111a503d' },
              guest: { _id: '67acc90e6c81408ce5418909' },
              accountId: '67853b83eab5de1fd4c47333',
              guestId: '67acc90e6c81408ce5418909',
              conversationId: '67acc90e2d225600118d1f21'
            }
          ),
          count: 14_622
        }
      }
    end

    context 'with filter by confirmation_code', vcr: { cassette_name: 'reservations/search/by_confirmation_code' } do
      let(:fields) { %w[_id listingId checkInDateLocalized checkOutDateLocalized status confirmationCode] }
      let(:attributes) { { confirmation_code: 'test_20260526_001' } }

      it_behaves_like 'successful call', value_containing: -> {
        {
          results: array_including(
            a_hash_including(
              _id: '6a16cb5e0e9ec09fac1bf576',
              confirmationCode: 'test_20260526_001',
              listingId: '67ee2d9c059de0003a2982be',
              checkInDateLocalized: '2026-07-01',
              checkOutDateLocalized: '2026-07-02',
              status: 'confirmed'
            )
          ),
          count: 1
        }
      }
    end

    context 'with filter by conversation_id', vcr: { cassette_name: 'reservations/search/by_conversation_id' } do
      let(:attributes) { { conversation_id: '681076f4449c980012deb0af' } }

      it_behaves_like 'successful call', value_containing: -> {
        {
          results: array_including(
            _id: '681077829605200010d12a42',
            integration: {
              platform: 'airbnb2',
              _id: '67e1e9cc14219fe46bde9681',
              limitations: {
                availableStatuses: []
              }
            },
            accountId: '67853b83eab5de1fd4c47333',
            guestId: '68107782cea427f4361abe89',
            guest: {
              _id: '68107782cea427f4361abe89'
            },
            listingId: '67e1ea3beb4ba10072a5f2ac',
            listing: { _id: '67e1ea3beb4ba10072a5f2ac' },
            conversationId: '681076f4449c980012deb0af'
          ),
          count: 1
        }
      }
    end

    context 'with filter by ids', vcr: { cassette_name: 'reservations/search/by_ids' } do
      let(:fields) { %w[_id guestId] }
      let(:take) { 3 }
      let(:attributes) { { ids: %w[67ef2397a7e0120013639de9 6aa3f3176b27db61c82ecbd9 6aa3d53238b6c0de2750c9bc] } }

      it_behaves_like 'successful call', value_containing: -> {
        {
          results: contain_exactly(
            a_hash_including(_id: '67ef2397a7e0120013639de9', guestId: be_a(String)),
            a_hash_including(_id: '6aa3f3176b27db61c82ecbd9', guestId: be_a(String)),
            a_hash_including(_id: '6aa3d53238b6c0de2750c9bc', guestId: be_a(String))
          ),
          count: 3
        }
      }
    end
  end

  context 'with invalid arguments' do
    context 'when no fields are requested' do
      let(:fields) { [] }
      let(:attributes) { { ids: ['reservation-1'] } }
      let(:message) { 'fields: required' }

      before do
        allow(Guesty).to receive(:do_request)
        result
      end

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError

      it 'preserves the fatal flag' do
        expect(result.failure).to have_attributes(fatal: true)
      end

      it 'does not call Guesty' do
        expect(Guesty).not_to have_received(:do_request)
      end
    end

    {
      'when the ids are empty' => {
        attributes: -> { { ids: [] } },
        message: 'ids: required'
      }
    }.each do |description, lets|
      context description do
        let(:attributes, &lets[:attributes])
        let(:message) { lets[:message] }

        it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
      end
    end
  end
end
