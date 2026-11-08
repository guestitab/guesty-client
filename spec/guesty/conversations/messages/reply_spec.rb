RSpec.describe Guesty::Conversations::Messages::Reply do
  include_context 'operations'

  let(:args) { { conversation_id:, module_type:, body: } }

  let(:conversation_id) { 'guesty-conversation-1' }
  let(:module_type) { 'airbnb2' }
  let(:body) { 'I need to check the availability.' }

  context 'with valid arguments', vcr: { cassette_name: 'conversations/messages/reply/sent' } do
    let(:endpoint) { "https://open-api.guesty.com/v1/communication/conversations/#{conversation_id}/send-message" }

    it_behaves_like 'successful call', value: -> {
      { message_id: 'guesty-message-2', conversation_id:, module_type:, body:, created_at: Time.zone.iso8601('2026-08-17T12:00:00.000Z') }
    }

    context 'without a module type', vcr: false do
      let(:module_type) { nil }

      before do
        stub_request(:post, endpoint).to_return(
          status: 200,
          body: {
            status: 200,
            data: { _id: 'guesty-message-3', conversationId: conversation_id, module: { type: 'email' }, body:, createdAt: '2026-09-11T12:00:00.000Z' }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        result
      end

      it_behaves_like 'successful call', value_containing: -> { hash_including(module_type: 'email') }

      it 'asks Guesty for the platform channel' do
        expect(WebMock).to have_requested(:post, endpoint).with(body: { module: { type: 'platform' }, body: })
      end
    end

    context 'when Guesty answers with a glitch error', vcr: false do
      before do
        stub_request(:post, endpoint).to_return(
          status: 500,
          body: { status: 500, error: { message: 'Write conflict during plan execution' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        result
      end

      it 'sends the message once' do
        expect(WebMock).to have_requested(:post, endpoint).once
      end
    end
  end

  describe '.module_type_for' do
    it 'answers direct bookings by email' do
      expect(%w[guestit core_manual core_group_manual].map { described_class.module_type_for(it) }).to all(eq('email'))
    end
  end
end
