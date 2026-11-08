RSpec.describe Guesty::Reservations::Decline do
  include_context 'operations'

  let(:args) { { reservation_id:, reason:, message: guest_message } }

  let(:reservation_id) { '6a06db716203cc0e830c0a0b' }
  let(:reason) { 'dates_not_available' }
  let(:guest_message) { 'Sorry, the home is not free on those dates.' }
  let(:endpoint) { "https://open-api.guesty.com/v1/reservations-v3/#{reservation_id}/decline" }

  context 'with valid arguments' do
    before do
      stub_request(:post, endpoint).with(body: { reason:, messageToGuest: guest_message })
                                   .to_return(status: 201, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it_behaves_like 'successful call', value: true
  end

  context 'with invalid arguments' do
    context 'when the reason is blank' do
      let(:reason) { '' }
      let(:message) { 'reason: required' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end

    context 'when the message is blank' do
      let(:guest_message) { ' ' }
      let(:message) { 'message: required' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end
  end
end
