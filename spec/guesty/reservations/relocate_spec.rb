RSpec.describe Guesty::Reservations::Relocate do
  include_context 'operations'

  let(:args) { { reservation_id: 'reservation-1', listing_id: 'listing-1', ignore_terms: true } }
  let(:endpoint) { 'https://open-api.guesty.com/v1/reservations-v3/reservation-1/relocate' }

  context 'with valid arguments' do
    before do
      stub_request(:put, endpoint).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      result
    end

    it_behaves_like 'successful call', value: true

    it 'puts the new listing' do
      expect(WebMock).to have_requested(:put, endpoint).with(body: { listingId: 'listing-1', ignoreTerms: true }).once
    end
  end

  context 'without a listing id' do
    let(:args) { { reservation_id: 'reservation-1', listing_id: '' } }
    let(:message) { 'listing_id: required' }

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
