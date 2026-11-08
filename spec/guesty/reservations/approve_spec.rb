RSpec.describe Guesty::Reservations::Approve do
  include_context 'operations'

  let(:args) { { reservation_id: } }

  let(:reservation_id) { '6a06db716203cc0e830c0a0b' }
  let(:endpoint) { "https://open-api.guesty.com/v1/reservations-v3/#{reservation_id}/approve" }

  context 'with valid arguments' do
    before { stub_request(:post, endpoint).to_return(status: 201, body: '', headers: { 'Content-Type' => 'application/json' }) }

    it_behaves_like 'successful call', value: true

    context 'when Guesty answers with a glitch error' do
      before do
        stub_request(:post, endpoint).to_return(
          status: 500,
          body: { status: 500, error: { message: 'Write conflict during plan execution' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        result
      end

      it 'sends the answer once' do
        expect(WebMock).to have_requested(:post, endpoint).once
      end
    end
  end
end
