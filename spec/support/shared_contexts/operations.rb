RSpec.shared_context 'operations' do # rubocop:disable RSpec/ContextWording
  subject(:result) { described_class.new.call(**args) }
end
