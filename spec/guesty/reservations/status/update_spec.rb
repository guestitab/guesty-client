RSpec.describe Guesty::Reservations::Status::Update do
  include_context 'operations'

  let(:args) { { reservation_id: '6a06db716203cc0e830c0a0b', attributes: } }

  let(:attributes) do
    {
      status: 'canceled',
      cancellationReason: 'No Reason Provided',
      cancellationNote: 'Test note'
    }
  end

  context 'with valid arguments', vcr: { cassette_name: 'reservations/status/update' } do
    it_behaves_like 'successful call', value: true
  end
end
