RSpec.describe Guesty::Guests::Profiles::Show do
  include_context 'operations'

  let(:args) { { guest_id:, fields: } }

  let(:guest_id) { '6819e3c13566dbd0562b9b84' }
  let(:fields) { %w[tags firstName] }

  context 'with valid arguments', vcr: { cassette_name: 'guests/profiles/show' } do
    it_behaves_like 'successful call', value_containing: -> { include(_id: '6819e3c13566dbd0562b9b84', firstName: 'Test') }
  end
end
