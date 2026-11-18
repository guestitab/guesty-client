RSpec.describe Guesty::Reservations::Resolutions::Index do
  include_context 'operations'

  let(:args) { { reservation_id:, created_at: } }

  let(:reservation_id) { '6525198fd60018000e7d6602' }
  let(:created_at) { Time.utc(2026, 10, 1, 12)..Time.utc(2026, 11, 18, 15) }
  let(:endpoint) { "https://open-api.guesty.com/v1/airbnb-resolutions-center/reservations/#{reservation_id}/resolutions" }
  let(:updated_at) { '2026-11-12T09:30:00.000Z' }
  let(:response_body) do
    {
      resolutions: [
        {
          _id: '6911f0c2a1b2c3d4e5f60718',
          resolutionId: 'CLA-T8P4ED545C',
          statusName: 'CLOSED',
          confirmationCode: 'HMJ82EN9Z8',
          currency: 'SEK',
          totalAmountRequested: 500,
          totalAmountPaid: 350.5,
          airbnbCreatedAt: '2026-11-08T10:00:00.000Z',
          airbnbUpdatedAt: updated_at
        }
      ],
      totalAmountRequested: 500,
      totalAmountPaid: 350.5,
      totalAmountCharged: 0
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
          external_id: 'CLA-T8P4ED545C',
          state: 'closed',
          amount_paid: BigDecimal('350.5'),
          currency: 'SEK',
          closed_at: Time.iso8601(updated_at)
        }
      ]
    }

    it 'requests the creation window in UTC' do
      result

      expect(WebMock).to have_requested(:get, endpoint).with(
        query: {
          'from' => '2026-10-01T12:00:00Z',
          'to' => '2026-11-18T15:00:00Z'
        }
      ).once
    end

    context 'when Airbnb has closed no request' do
      let(:response_body) { { resolutions: [], totalAmountRequested: 0, totalAmountPaid: 0, totalAmountCharged: 0 } }

      it_behaves_like 'successful call', value: []
    end

    context 'when a resolution has no update time' do
      let(:updated_at) { nil }

      it 'leaves the closing time empty' do
        expect(result.value!.sole).to include(closed_at: nil)
      end
    end

    context 'when Guesty answers something other than a resolutions list' do
      let(:response_body) { {} }
      let(:message) { 'Guesty resolutions response has an unexpected shape.' }

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end
  end

  context 'with invalid arguments' do
    context 'when the reservation id is blank' do
      let(:reservation_id) { '' }
      let(:message) { 'reservation_id: required' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end

    context 'when the creation window is open-ended' do
      let(:created_at) { Time.utc(2026, 10, 1).. }
      let(:message) { 'created_at: invalid' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end
  end
end
