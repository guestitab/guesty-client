RSpec.describe Guesty::Conversations::Search do
  include_context 'operations'

  let(:args) { { external_id: } }

  let(:external_id) { '6935779d2c1ef50013ec8835' }

  context 'with valid arguments', vcr: { cassette_name: 'conversations/search/by_reservation' } do
    it_behaves_like 'successful call', value: { id: '6935776e986f1c0011038b7b', reservations: [{ id: '6935779d2c1ef50013ec8835', closed: false }] }

    context 'when no conversation matches', vcr: { cassette_name: 'conversations/search/empty' } do
      it_behaves_like 'successful call', value: nil
    end
  end
end
