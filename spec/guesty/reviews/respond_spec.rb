RSpec.describe Guesty::Reviews::Respond do
  include_context 'operations'

  let(:args) { { review_id:, text: } }

  let(:review_id) { '67e41198c664dd30e3b4ad35' }
  let(:text) { 'Thank you for your feedback. We appreciate your review and will work to improve.' }

  context 'with valid arguments', vcr: { cassette_name: 'reviews/respond' } do
    it_behaves_like 'successful call', value: true
  end
end
