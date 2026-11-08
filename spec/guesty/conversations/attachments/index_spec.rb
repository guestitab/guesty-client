RSpec.describe Guesty::Conversations::Attachments::Index do
  include_context 'operations'

  let(:args) { { keys: } }

  let(:keys) { [jpeg_key, png_key] }
  let(:jpeg_key) { 'production/67853b83eab5de1fd4c47333/jpeg/60a5fa8262e3a0fea0e6e42528a22ce6_broken-window.jpeg' }
  let(:png_key) { 'production/67853b83eab5de1fd4c47333/png/7c1e0b4f2a9d3e6b8c5a0f1d2e3b4c5d_kitchen-1.png' }

  context 'with valid arguments', vcr: { cassette_name: 'conversations/attachments/index/two_keys' } do
    it_behaves_like 'successful call', value: -> {
      {
        jpeg_key => "https://guesty-ugc.s3.amazonaws.com/#{jpeg_key}?AWSAccessKeyId=ASIAEXAMPLE&Expires=1789491526&Signature=abc123",
        png_key => "https://guesty-ugc.s3.amazonaws.com/#{png_key}?AWSAccessKeyId=ASIAEXAMPLE&Expires=1789491526&Signature=def456"
      }
    }

    context 'with a link as the key', vcr: false do
      let(:keys) { ['https://cdn.guesty.com/attachments/kitchen-1.png'] }

      it_behaves_like 'successful call', value: { 'https://cdn.guesty.com/attachments/kitchen-1.png' => 'https://cdn.guesty.com/attachments/kitchen-1.png' }
    end

    context 'with more storage keys than BATCH_SIZE', vcr: false do
      let(:keys) { Array.new(described_class::BATCH_SIZE + 1) { |index| format('production/key-%02d', index) } }
      let(:endpoint) { 'https://open-api.guesty.com/v1/communication/conversations/get-attachments' }

      before do
        stub_request(:get, endpoint).with(query: hash_including({})).to_return do |request|
          batch = URI.decode_www_form(request.uri.query).filter_map { |name, value| value if name == 'keys[]' }
          { status: 200, body: { status: 200, data: batch.map { |key| "https://cdn/#{key}" } }.to_json, headers: { 'Content-Type' => 'application/json' } }
        end

        result
      end

      it_behaves_like 'successful call', value: -> { keys.index_with { |key| "https://cdn/#{key}" } }

      it 'requests the keys in slices of BATCH_SIZE' do
        expect(a_request(:get, endpoint).with(query: { 'keys' => keys.first(described_class::BATCH_SIZE) })).to have_been_made.once
        expect(a_request(:get, endpoint).with(query: { 'keys' => keys.drop(described_class::BATCH_SIZE) })).to have_been_made.once
      end
    end

    context 'when Guesty answers something other than a link list',
            vcr: { cassette_name: 'conversations/attachments/index/unexpected_shape' } do
      let(:keys) { [jpeg_key] }
      let(:message) { 'Guesty attachments response has an unexpected shape.' }

      it_behaves_like 'failed call', failure_class: Guesty::Error
    end
  end

  context 'with invalid arguments' do
    context 'when a key is blank' do
      let(:keys) { [jpeg_key, ''] }
      let(:message) { 'keys: invalid' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end
  end
end
