RSpec.describe Guesty::Reservations::Show do
  subject(:result) { described_class.new.call(**args) }

  let(:args) { { reservation_id: '6835c385fe621d0026ce5511', fields: %w[_id listing._id guest.firstName guest.lastName] } }

  context 'with valid arguments', vcr: { cassette_name: 'reservations/show' } do
    it 'returns the reservation attributes' do
      expect(result.value!).to eq(
        _id: '6835c385fe621d0026ce5511',
        integration: { platform: 'airbnb2', _id: '67e1c741cebc2423ab539ef6', limitations: { availableStatuses: [] } },
        accountId: '67853b83eab5de1fd4c47333',
        guestId: '6835c3847572b11a7e7e6eef',
        guest: { _id: '6835c3847572b11a7e7e6eef', firstName: 'Test', lastName: 'Guestsson' },
        listingId: '67e1c7c2a7bd17007449b163',
        listing: { _id: '67e1c7c2a7bd17007449b163' }
      )
    end
  end

  context 'without a reservation id' do
    let(:args) { { reservation_id: '', fields: %w[_id] } }
    let(:message) { 'reservation_id: required' }

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
  end
end
