RSpec.describe Guesty::Guests::Profiles::Create do
  include_context 'operations'

  let(:args) { { attributes: } }

  let(:attributes) do
    {
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      emails: ['tim.apple@example.com'],
      phone: '+46700000000'
    }
  end

  context 'with valid arguments', vcr: { cassette_name: 'guests/profiles/create' } do
    it_behaves_like 'successful call', value_containing: -> { include(_id: '67deb7fde1a3acd9ac9c36b3') }
  end

  context 'with invalid arguments' do
    context 'when the lastName is blank' do
      let(:attributes) { super().except(:lastName) }
      let(:message) { 'lastName: required' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end
  end
end
