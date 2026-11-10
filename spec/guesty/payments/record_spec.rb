RSpec.describe Guesty::Payments::Record do
  include_context 'operations'

  let(:args) { { reservation_id:, attributes: } }
  let(:attributes) do
    {
      amount:,
      paid_at:,
      note:
    }
  end
  let(:reservation_id) { '67ebc9c7c5904c0010502f89' }
  let(:amount) { 4379.62 }
  let(:paid_at) { Time.utc(2025, 4, 1, 12, 30) }
  let(:note) { 'Payment recorded in Guestit.se / Stripe pi_3SFm2kAD4JnZ5KcB1qX9vT7L' }
  let(:endpoint) { 'https://open-api.guesty.com/v1/payments/record' }
  let(:payment) do
    {
      _id: '64da25d683ad1500284bd0ef',
      reservationId: reservation_id,
      status: 'SUCCEEDED',
      amount:,
      currency: 'SEK',
      note:
    }
  end

  context 'with valid arguments' do
    before do
      stub_request(:post, endpoint).to_return(status: 201, body: payment.to_json, headers: { 'Content-Type' => 'application/json' })

      result
    end

    it_behaves_like 'successful call', value: -> { payment }

    it 'posts the recorded payment' do
      expect(WebMock).to have_requested(:post, endpoint).with(
        body: {
          reservationId: reservation_id,
          amount: 4379.62,
          paymentMethod: { method: 'RECORDED_CASH' },
          shouldBePaidAt: '2025-04-01T12:30:00.000Z',
          note:
        }
      ).once
    end

    context 'with a date as paid_at' do
      let(:paid_at) { Date.new(2025, 4, 1) }

      it 'records it at midnight UTC' do
        expect(WebMock).to have_requested(:post, endpoint).with(body: hash_including(shouldBePaidAt: '2025-04-01T00:00:00.000Z')).once
      end
    end
  end

  context 'with an unknown method' do
    let(:attributes) { { amount:, paid_at:, note:, method: 'CASH' } }
    let(:message) { 'method: invalid' }

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
  end

  context 'with a note past the wire limit' do
    let(:note) { 'a' * 501 }
    let(:message) { 'note: invalid' }

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
  end

  context 'when the reservation is not ready for payments' do
    let(:error_body) do
      {
        error: {
          message: 'Reservation is not ready for payments yet, no payment was created. Please retry later.',
          code: 'PAYMENT_RESERVATION_NOT_READY',
          status: 503,
          data: { paymentCreated: false }
        }
      }
    end

    before do
      stub_request(:post, endpoint).to_return(status: 503, body: error_body.to_json, headers: { 'Content-Type' => 'application/json' })

      result
    end

    it_behaves_like 'failed call', failure_class: Guesty::ApiError

    it 'classifies the failure as transient' do
      expect(result.failure).to be_transient
    end
  end
end
