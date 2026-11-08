# rubocop:disable-next RSpec/ContextWording
RSpec.shared_context 'operations' do
  let(:operation) { described_class }
  let(:result) { method.call(args) }

  let(:method) { ->(args) { operation.new.call(**args) } }

  let :args do
    raise NotImplementedError, 'Please implement :args to use :operations context'
  end
end
