RSpec.describe Guesty::Homes::Search do
  include_context 'operations'

  let(:args) { { attributes:, skip: 0, take: 2 } }

  let(:attributes) do
    {
      response_keys: %w[_id type],
      filters: [{ operator: '$eq', field: 'type', value: 'MTL_CHILD' }]
    }
  end

  context 'with valid arguments', vcr: { cassette_name: 'homes/search' } do
    it_behaves_like 'successful call', value_containing: -> {
      {
        results: array_including(a_hash_including(_id: '6806bf27c1d93b0011c81505', type: 'MTL_CHILD')),
        count: 348
      }
    }
  end
end
