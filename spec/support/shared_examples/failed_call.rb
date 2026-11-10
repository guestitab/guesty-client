RSpec.shared_examples 'failed call' do |failure_class: nil|
  it 'fails with the error' do
    expect(result).to be_failure
    expect(result.failure).to be_a(failure_class) if failure_class
    expect(result.failure.message).to eq(message) if respond_to?(:message)
    expect(result.failure.fatal).to be(fatal) if respond_to?(:fatal)
  end
end
