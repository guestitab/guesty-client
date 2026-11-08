RSpec.describe Guesty::Reservations::Update do
  include_context 'operations'

  let(:args) { { reservation_id: '67ef3355b7c0bb000fa668d5', attributes: } }

  let(:attributes) do
    {
      checkInDateLocalized: Date.new(2025, 4, 9),
      checkOutDateLocalized: Date.new(2025, 4, 12),
      totalPrice: 1000
    }
  end

  context 'with valid arguments', vcr: { cassette_name: 'reservations/update' } do
    it_behaves_like 'successful call', value: true
  end
end
