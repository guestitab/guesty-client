RSpec.describe Guesty::Reservations::ConfirmationCode::Update do
  include_context 'operations'

  let(:args) { { reservation_id: 'reservation-1', confirmation_code: } }
  let(:confirmation_code) { 'ABCDE-12345' }
  let(:endpoint) { 'https://open-api.guesty.com/v1/reservations-v3/reservation-1/confirmation-code' }

  context 'with valid arguments' do
    before do
      stub_request(:put, endpoint).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      result
    end

    it_behaves_like 'successful call', value: true

    it 'puts the confirmation code' do
      expect(WebMock).to have_requested(:put, endpoint).with(body: { confirmationCode: 'ABCDE-12345' }).once
    end
  end

  context 'with a code below the minimum length' do
    let(:confirmation_code) { 'ABC' }
    let(:message) { 'confirmation_code: invalid' }

    it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
  end
end
