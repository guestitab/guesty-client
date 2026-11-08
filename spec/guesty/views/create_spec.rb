RSpec.describe Guesty::Views::Create do
  include_context 'operations'

  let(:args) { { title:, section: } }

  let(:title) { 'Filter name' }
  let(:section) { 'reservations' }

  context 'with valid arguments', vcr: { cassette_name: 'views/create' } do
    it_behaves_like 'successful call', value_containing: -> { include(title: 'Filter name', section: 'reservations') }
  end
end
