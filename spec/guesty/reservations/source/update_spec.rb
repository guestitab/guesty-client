RSpec.describe Guesty::Reservations::Source::Update do
  include_context 'operations'

  let(:args) { { reservation_id: 'reservation-1', source: 'manual', apply_recalculation: false } }
  let(:endpoint) { 'https://open-api.guesty.com/v1/reservations-v3/reservation-1/source' }

  context 'with valid arguments' do
    before do
      stub_request(:put, endpoint).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      result
    end

    it_behaves_like 'successful call', value: true

    it 'puts the source without a recalculation' do
      expect(WebMock).to have_requested(:put, endpoint).with(body: { source: 'manual', applyRecalculation: false }).once
    end
  end

  context 'without a source' do
    let(:args) { { reservation_id: 'reservation-1', source: '' } }
    let(:message) { 'source: required' }

    before do
      allow(Guesty).to receive(:do_request)
      result
    end

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError

    it 'does not call Guesty' do
      expect(Guesty).not_to have_received(:do_request)
    end
  end
end
