RSpec.describe Guesty::Views::Update do
  include_context 'operations'

  let(:args) { { id:, **attributes } }

  let(:id) { '6a59e34b266455002d30ad29' }
  let(:attributes) do
    {
      title: 'Filter name',
      fields: 'confirmationCode guest checkIn checkOut listing',
      filters: [
        {
          field: '_id',
          operator: '$in',
          value: ['6a577f7c59abc36c27341908']
        }
      ],
      sort: 'checkIn'
    }
  end

  context 'with valid arguments', vcr: { cassette_name: 'views/update' } do
    it_behaves_like 'successful call', value_containing: -> { include(_id: id, title: 'Filter name', section: 'reservations') }
  end

  context 'with invalid arguments' do
    context 'when the attributes are all nil' do
      let(:attributes) { {} }
      let(:message) { 'attributes: invalid' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end
  end
end
