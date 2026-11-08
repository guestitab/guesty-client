RSpec.describe Guesty::Reservations::Create do
  include_context 'operations'

  let(:args) { { attributes: } }

  let(:attributes) do
    {
      guestId: '6a06c68212b85ea2a96d3621',
      listingId: '67ee2d9c059de0003a2982be',
      source: 'guestit',
      status: 'confirmed',
      ignoreCalendar: true,
      ignoreTerms: true,
      confirmedAt: Date.new(2026, 5, 27),
      guestsCount: 2,
      checkInDateLocalized: Date.new(2026, 6, 25),
      checkOutDateLocalized: Date.new(2026, 6, 27),
      accommodationFare: '100.0',
      cleaningFee: '50.0',
      numberOfGuests: {
        numberOfAdults: 1,
        numberOfChildren: 1
      }
    }
  end

  context 'with valid arguments', vcr: { cassette_name: 'reservations/create' } do
    before do
      allow(Guesty).to receive(:connection).and_call_original

      result
    end

    it_behaves_like 'successful call', value: '6a16cd9a31056afb2fbb7b61'

    it 'calls Guesty.connection with a timeout of a minute' do
      expect(Guesty).to have_received(:connection).with(timeout: 60)
    end
  end

  context 'with invalid arguments' do
    {
      'when the status is missing' => {
        attributes: -> { super().except(:status) },
        message: 'status: required'
      },
      'when the numberOfGuests has no numberOfAdults' => {
        attributes: -> { super().merge(numberOfGuests: {}) },
        message: 'numberOfAdults: required'
      }
    }.each do |description, lets|
      context description do
        let(:attributes, &lets[:attributes])
        let(:message) { lets[:message] }

        it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
      end
    end
  end
end
