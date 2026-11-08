RSpec.describe Guesty::Reservations::AccommodationFare::Update do
  include_context 'operations'

  let(:args) { { reservation_id:, amount: } }
  let(:reservation_id) { '6acf3bda70d73ecc8937de5e' }
  let(:amount) { 3600 }
  let(:endpoint) { 'https://open-api.guesty.com/v1/price-adjustments/manual-total-amount' }

  context 'with valid arguments' do
    context 'when Guesty has a lower fare', vcr: { cassette_name: 'reservations/accommodation_fare/update/adjust' } do
      before { result }

      it_behaves_like 'successful call', value: 1200

      it 'adjusts the accommodation fare by the difference' do
        expect(WebMock).to have_requested(:post, endpoint).with(body: { reservationId: reservation_id, priceAdjustments: [{ normalType: 'AF', amount: 1200.0 }] }).once
      end
    end

    context 'when Guesty has a higher fare', vcr: { cassette_name: 'reservations/accommodation_fare/update/decrease' } do
      let(:reservation_id) { '6acfa83dee6ae3f00da2bfd4' }
      let(:amount) { 900 }

      before { result }

      it_behaves_like 'successful call', value: -1500

      it 'adjusts the accommodation fare by the difference' do
        expect(WebMock).to have_requested(:post, endpoint).with(body: { reservationId: reservation_id, priceAdjustments: [{ normalType: 'AF', amount: -1500.0 }] }).once
      end
    end

    context 'when Guesty has discounted the fare to the amount', vcr: { cassette_name: 'reservations/accommodation_fare/update/discounted' } do
      let(:reservation_id) { '6acfa83dee6ae3f00da2bfd4' }
      let(:amount) { 900 }

      before { result }

      it_behaves_like 'successful call', value: 0

      it 'does not adjust the accommodation fare' do
        expect(WebMock).not_to have_requested(:post, endpoint)
      end
    end

    context 'when Guesty has the same fare', vcr: { cassette_name: 'reservations/accommodation_fare/update/unchanged' } do
      before { result }

      it_behaves_like 'successful call', value: 0

      it 'does not adjust the accommodation fare' do
        expect(WebMock).not_to have_requested(:post, endpoint)
      end
    end

    context 'when Guesty has no such reservation', vcr: { cassette_name: 'reservations/accommodation_fare/update/missing' } do
      let(:reservation_id) { '6acf00000000000000000000' }

      before { result }

      it_behaves_like 'failed call', failure_class: Guesty::ApiError
    end
  end
end
