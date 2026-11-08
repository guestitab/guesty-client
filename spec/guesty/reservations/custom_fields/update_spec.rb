RSpec.describe Guesty::Reservations::CustomFields::Update do
  include_context 'operations'

  let(:args) { { reservation_id: '67eecfe9543d7c0012467e5d', custom_fields: [{ fieldId: '6821ff700090ff004bcc8175', value: 'false' }] } }

  context 'with valid arguments',
          vcr: { cassette_name: 'reservations/custom_fields/update/success' } do
    it_behaves_like 'successful call', value_containing: -> {
      {
        reservationId: '67eecfe9543d7c0012467e5d',
        customFields: include(hash_including(fieldId: '6821ff700090ff004bcc8175', value: false))
      }
    }
  end
end
