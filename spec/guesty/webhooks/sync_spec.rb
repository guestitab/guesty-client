RSpec.describe Guesty::Webhooks::Sync do
  include_context 'operations'

  let(:args) { { urls:, events: } }

  let(:urls) { ['https://core.example.com/webhooks/guesty', 'https://staging.example.com/webhooks/guesty'] }
  let(:events) { ['reservation.new', 'calendar.updated.v2'] }
  let(:existing) { [] }
  let(:index) { operation_stub(Guesty::Webhooks::Index) }
  let(:create) { operation_stub(Guesty::Webhooks::Create) }
  let(:update) { operation_stub(Guesty::Webhooks::Update) }

  before do
    allow(index).to receive(:call).and_return(Success(existing))
    allow(create).to receive(:call).and_return(Success({}))
    allow(update).to receive(:call).and_return(Success({}))

    result
  end

  context 'with valid arguments' do
    it_behaves_like 'successful call', value: -> { { created: urls } }

    it 'calls Guesty::Webhooks::Create for each url and not Guesty::Webhooks::Update' do
      expect(create).to have_received(:call).with(url: urls.first, events:)
      expect(create).to have_received(:call).with(url: urls.last, events:)
      expect(update).not_to have_received(:call)
    end

    context 'with existing webhooks for the urls' do
      let(:existing) do
        [
          { _id: 'wh_1', url: "#{urls.first} ", events: ['reservation.new'] },
          { _id: 'wh_2', url: urls.last, events: events.reverse }
        ]
      end

      it_behaves_like 'successful call', value: -> { { updated: [urls.first], unchanged: [urls.last] } }

      it 'calls Guesty::Webhooks::Update for the webhook whose events drifted and not Guesty::Webhooks::Create' do
        expect(update).to have_received(:call).once.with(id: 'wh_1', url: urls.first, events:)
        expect(create).not_to have_received(:call)
      end
    end
  end
end
