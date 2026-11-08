RSpec.describe Guesty::GuestFolio::InvoiceItems::Index do
  include_context 'operations'

  let(:args) { { reservation_id: } }

  let(:reservation_id) { '64a1f2c3e4b0a1b2c3d4e5f6' }
  let(:endpoint) { 'https://open-api.guesty.com/v1/guest-folio/invoice-items' }
  let(:created_at) { '2026-01-20T14:00:00.000Z' }
  let(:response_body) do
    {
      results: [
        {
          reservationId: reservation_id,
          currency: 'SEK',
          invoiceItems: [
            { id: 'resolution-1', normalType: 'ARC', totalPrice: -250.5, logs: { createdAt: created_at } },
            { id: 'fare-1', normalType: 'AF', totalPrice: 600 }
          ]
        }
      ],
      notFound: []
    }
  end

  before do
    stub_request(:get, endpoint).with(query: hash_including({})).to_return(
      status: 200,
      body: response_body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  context 'with valid arguments' do
    it_behaves_like 'successful call', value: -> {
      [
        {
          external_id: 'resolution-1',
          normal_type: 'ARC',
          amount: BigDecimal('-250.5'),
          currency: 'SEK',
          occurred_at: Time.iso8601(created_at)
        },
        {
          external_id: 'fare-1',
          normal_type: 'AF',
          amount: BigDecimal('600'),
          currency: 'SEK',
          occurred_at: nil
        }
      ]
    }

    it 'requests the folio fields the importer reads' do
      result

      expect(WebMock).to have_requested(:get, endpoint).with(
        query: {
          'reservationIds' => reservation_id,
          'fields' => 'normalType,totalPrice,logs.createdAt'
        }
      ).once
    end

    context 'when the reservation is not found' do
      let(:response_body) { { results: [], notFound: [reservation_id] } }

      it_behaves_like 'successful call', value: []
    end

    context 'when Guesty answers something other than a folio result' do
      let(:response_body) { {} }
      let(:message) { 'Guesty invoice items response has an unexpected shape.' }

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end
  end

  context 'with invalid arguments' do
    context 'when the reservation id is blank' do
      let(:reservation_id) { '' }
      let(:message) { 'reservation_id: required' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError

      it 'does not call Guesty' do
        result

        expect(WebMock).not_to have_requested(:get, endpoint)
      end
    end
  end
end
