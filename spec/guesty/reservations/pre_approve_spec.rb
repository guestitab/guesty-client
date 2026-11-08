RSpec.describe Guesty::Reservations::PreApprove do
  include_context 'operations'

  let(:args) { { reservation_id: '6a06db716203cc0e830c0a0b' } }

  context 'with valid arguments' do
    before do
      stub_request(:post, 'https://open-api.guesty.com/v1/reservations-v3/6a06db716203cc0e830c0a0b/pre-approve')
        .to_return(status: 201, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it_behaves_like 'successful call', value: true
  end
end
