RSpec.describe Guesty::Conversations::Show do
  include_context 'operations'

  let(:args) { { conversation_id: } }

  let(:conversation_id) { 'guesty-conversation' }

  context 'with valid arguments' do
    before do
      stub_request(:get, "https://open-api.guesty.com/v1/communication/conversations/#{conversation_id}").with(query: { fields: described_class::FIELDS }).to_return(
        status: 200,
        body: {
          status: 200,
          data: { _id: conversation_id, meta: { reservations: [{ _id: 'open-stay', status: 'confirmed' }, { _id: 'lost-inquiry', status: 'expired' }, { status: 'inquiry' }] } }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    it_behaves_like 'successful call', value: {
      id: 'guesty-conversation', reservations: [{ id: 'open-stay', closed: false }, { id: 'lost-inquiry', closed: true }]
    }
  end
end
