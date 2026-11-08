RSpec.describe Guesty::Guests::Profiles::Update do
  include_context 'operations'

  let(:args) { { guest_id:, attributes: } }

  let(:guest_id) { '67deb7fde1a3acd9ac9c36b3' }
  let(:attributes) do
    {
      firstName: 'Tim',
      lastName: 'Apple',
      email: 'john.doe@example.com',
      emails: ['tim.apple@example.com'],
      phone: '+46700000000'
    }
  end

  context 'with valid arguments', vcr: { cassette_name: 'guests/profiles/update' } do
    it_behaves_like 'successful call', value_containing: -> { include(_id: '67deb7fde1a3acd9ac9c36b3', firstName: 'Tim') }
  end
end
