RSpec.describe Guesty::Conversations::Index do
  include_context 'operations'

  let(:args) { { since: } }

  let(:since) { Time.zone.local(2026, 8, 19, 15, 30) }

  context 'with valid arguments', vcr: { cassette_name: 'conversations/index/two_pages' } do
    it_behaves_like 'successful call', value: [
      { id: 'conversation-newest', reservations: [{ id: 'reservation-newest', closed: false }, { id: 'reservation-newest-sibling', closed: true }] },
      { id: 'conversation-in-window', reservations: [{ id: 'reservation-in-window', closed: false }] }
    ]

    context 'when the window reaches into the next page' do
      let(:since) { Time.zone.local(2026, 8, 19, 15) }

      it_behaves_like 'successful call', value: [
        { id: 'conversation-newest', reservations: [{ id: 'reservation-newest', closed: false }, { id: 'reservation-newest-sibling', closed: true }] },
        { id: 'conversation-in-window', reservations: [{ id: 'reservation-in-window', closed: false }] },
        { id: 'conversation-stale', reservations: [{ id: 'reservation-stale', closed: true }] }
      ]
    end

    context 'when the pages exceed MAX_PAGES', vcr: false do
      let(:page) do
        {
          conversations: [{ _id: 'conversation-newest', updatedAt: 1.minute.since(since).iso8601, meta: { reservations: [{ _id: 'reservation-newest' }] } }],
          cursor: { after: 'next-page' }
        }
      end
      let(:message) { "Guesty conversations pagination exceeded 2 pages since #{since.iso8601}" }

      before do
        stub_const("#{described_class}::MAX_PAGES", 2)
        stub_request(:get, 'https://open-api.guesty.com/v1/communication/conversations')
          .with(query: hash_including({}))
          .to_return(status: 200, body: { status: 200, data: page }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end
  end
end
