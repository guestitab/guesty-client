RSpec.describe Guesty::Reservations::Payments::Create do
  include_context 'operations'

  let(:args) { { reservation_id:, attributes: } }

  let(:reservation_id) { '67ebc9c7c5904c0010502f89' }
  let(:attributes) do
    {
      amount:,
      paid_at:,
      payment_intent_id:
    }
  end
  let(:amount) { 4379.62 }
  let(:paid_at) { Date.new(2025, 4, 1) }
  let(:payment_intent_id) { 'pi_3SFm2kAD4JnZ5KcB1qX9vT7L' }

  context 'with valid arguments' do
    let(:index_endpoint) { 'https://open-api.guesty.com/v1/payments' }
    let(:record_endpoint) { 'https://open-api.guesty.com/v1/payments/record' }
    let(:summary) do
      {
        currency: 'SEK',
        isFullyPaid: fully_paid,
        payments:,
        totalPaid: total_paid
      }
    end
    let(:fully_paid) { false }
    let(:payments) { [{ note: }] }
    let(:total_paid) { 0 }
    let(:note) { 'Payment recorded in Guestit.se / Stripe pi_3R9yQeAD4JnZ5KcB1sBT8Tgk' }
    let(:payment_response) do
      {
        status: 201,
        body: { _id: '64da25d683ad1500284bd0ef', reservationId: reservation_id, status: 'SUCCEEDED' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      }
    end

    before do
      stub_request(:get, index_endpoint)
        .with(query: { reservationId: reservation_id })
        .to_return(status: 200, body: summary.to_json, headers: { 'Content-Type' => 'application/json' })
      stub_request(:post, record_endpoint).to_return(payment_response)

      result
    end

    it_behaves_like 'successful call'

    it 'records the payment with the payment intent in the note' do
      expect(WebMock).to have_requested(:post, record_endpoint).with(
        body: {
          reservationId: reservation_id,
          amount: 4379.62,
          paymentMethod: { method: 'RECORDED_CASH' },
          shouldBePaidAt: '2025-04-01T00:00:00.000Z',
          note: 'Payment recorded in Guestit.se / Stripe pi_3SFm2kAD4JnZ5KcB1qX9vT7L'
        }
      ).once
    end

    context 'when the reservation is fully paid' do
      let(:fully_paid) { true }
      let(:payments) { nil }

      it_behaves_like 'successful call'

      it 'does not post the payment' do
        expect(WebMock).not_to have_requested(:post, record_endpoint)
      end
    end

    context 'when the payment is recorded' do
      let(:note) { 'Payment recorded in Guestit.se / Stripe pi_3SFm2kAD4JnZ5KcB1qX9vT7L' }

      it_behaves_like 'successful call'

      it 'does not post the payment' do
        expect(WebMock).not_to have_requested(:post, record_endpoint)
      end
    end

    context 'when the payment list is null and nothing has been paid' do
      let(:payments) { nil }

      it_behaves_like 'successful call'

      it 'posts the payment once' do
        expect(WebMock).to have_requested(:post, record_endpoint).once
      end
    end

    context 'when the payment list is absent and nothing has been paid' do
      let(:summary) { super().except(:payments) }

      it_behaves_like 'successful call'

      it 'posts the payment once' do
        expect(WebMock).to have_requested(:post, record_endpoint).once
      end
    end

    {
      'a previous payment' => 100,
      'an unknown paid amount' => nil
    }.each do |state, paid_amount|
      context "with #{state} and no payment history" do
        let(:payments) { nil }
        let(:total_paid) { paid_amount }
        let(:message) { 'Guesty has not returned the payment history yet. Try again later.' }
        let(:fatal) { false }

        it_behaves_like 'failed call', failure_class: Guesty::Error

        it 'does not post the payment' do
          expect(WebMock).not_to have_requested(:post, record_endpoint)
        end
      end
    end

    context 'when the post fails' do
      let(:payment_response) do
        {
          status: 500,
          body: { error: { message: 'Reservation Meta not found', status: 500 } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        }
      end
      let(:message) { 'Reservation Meta not found' }

      it_behaves_like 'failed call', failure_class: Guesty::ApiError

      it 'posts the payment once' do
        expect(WebMock).to have_requested(:post, record_endpoint).once
      end
    end
  end

  context 'with invalid arguments' do
    context 'when the payment_intent_id is blank' do
      let(:payment_intent_id) { nil }
      let(:message) { 'payment_intent_id: required' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end

    context 'when the amount is zero' do
      let(:amount) { 0 }
      let(:message) { 'amount: must_be_positive' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end
  end
end
