RSpec.describe Guesty::Reservations::Flags::Update do
  include_context 'operations'

  let(:args) { { reservation_id: 'reservation-1', flags: } }

  let(:flags) { { grants_created: true, grants_partial: false } }
  let(:body) do
    {
      customFields: [
        { fieldId: Guesty.config.custom_fields.fetch(:grants_created), value: 'true' },
        { fieldId: Guesty.config.custom_fields.fetch(:grants_partial), value: 'false' }
      ]
    }
  end

  before do
    stub_request(:put, 'https://open-api.guesty.com/v1/reservations-v3/reservation-1/custom-fields')
      .with(body:)
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

    result
  end

  it_behaves_like 'successful call', value: true
end
