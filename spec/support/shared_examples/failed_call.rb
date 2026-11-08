RSpec.shared_examples_for 'failed call' do |options = {}|
  raise "Unknown arguments: #{options.keys.without(:failure_class)}" if options.keys.without(:failure_class).any?

  let(:failure_class) { options[:failure_class] }

  let :message do
    if defined?(super)
      super()
    elsif !failure_class
      raise NotImplementedError, 'Please either implement :message or provide :failure_class argument to use :failed_call examples'
    end
  end

  # Pin the retry semantics of the failure with `let(:fatal) { true }` or `{ false }`.
  let :fatal do
    super() if defined?(super)
  end

  it 'fails with the exception' do
    expect(result).to be_failure
    expect(result.failure).to be_a(failure_class) if failure_class

    case message
    when String
      expect(result.failure.message).to eq(message)
    when Regexp
      expect(result.failure.message).to match(message)
    end

    expect(result.failure.fatal).to be(fatal) unless fatal.nil?
  end
end
