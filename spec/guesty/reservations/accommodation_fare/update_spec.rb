RSpec.describe Guesty::Reservations::AccommodationFare::Update do
  include_context 'operations'

  let(:args) { { reservation_id:, amount: } }
  let(:reservation_id) { '6acf3bda70d73ecc8937de5e' }
  let(:amount) { 3600 }
  let(:endpoint) { 'https://open-api.guesty.com/v1/price-adjustments/manual-total-amount' }
  let(:folio_endpoint) { 'https://open-api.guesty.com/v1/guest-folio/invoice-items' }
  let(:invoice_items) { [{ id: 'item-1', normalType: 'AF', totalPrice: current_fare }] }
  let(:current_fare) { 2400 }
  let(:folio_body) do
    {
      results: [{ reservationId: reservation_id, currency: 'SEK', invoiceItems: invoice_items }],
      notFound: []
    }
  end

  before do
    stub_request(:get, folio_endpoint)
      .with(query: { reservationIds: reservation_id, fields: 'normalType,totalPrice,logs.createdAt' })
      .to_return(status: 200, body: folio_body.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:post, endpoint).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
  end

  context 'when Guesty has a lower fare' do
    before { result }

    it_behaves_like 'successful call', value: 1200

    it 'adjusts the accommodation fare by the difference' do
      expect(WebMock).to have_requested(:post, endpoint).with(body: { reservationId: reservation_id, priceAdjustments: [{ normalType: 'AF', amount: 1200.0 }] }).once
    end
  end

  context 'when Guesty has discounted the fare to the amount' do
    let(:amount) { 900 }
    let(:invoice_items) { [{ id: 'item-1', normalType: 'AF', totalPrice: 1400 }, { id: 'item-2', normalType: 'AFD', totalPrice: -500 }] }

    before { result }

    it_behaves_like 'successful call', value: 0

    it 'does not adjust the accommodation fare' do
      expect(WebMock).not_to have_requested(:post, endpoint)
    end
  end

  context 'when Guesty has no such reservation' do
    let(:folio_body) { { results: [], notFound: [reservation_id] } }
    let(:message) { 'Unknown reservation' }

    before do
      stub_request(:post, endpoint).to_return(
        status: 422,
        body: { error: { message: 'Unknown reservation', status: 422 } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      result
    end

    it_behaves_like 'failed call', failure_class: Guesty::ApiError
  end
end
