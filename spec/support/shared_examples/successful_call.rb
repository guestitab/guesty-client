RSpec.shared_examples 'successful call' do |value_type: nil, value_containing: nil, **rest|
  let(:expected)  { resolve_expected(rest[:value]) }
  let(:contained) { resolve_expected(value_containing) }

  raise "Unknown arguments: #{rest.keys.without(:value)}" if rest.keys.without(:value).any?

  it 'completes successfully and returns the expected data' do
    aggregate_failures do
      assert_success
      assert_type(value_type) if value_type
      assert_exact_value      if rest.key?(:value)
      assert_contains_sub     if value_containing
    end
  end

  private

  def assert_success
    expect(result).to be_success_monad
  end

  def assert_type(value_type)
    actual = result.value!
    expect(actual).to be_a(value_type),
                      "Expected type #{value_type}, got #{actual.class}"
  end

  def assert_exact_value
    actual = result.value!
    expect(actual).to eq(expected),
                      <<~MSG
                        exact-value mismatch:
                          expected: #{expected.inspect}
                          got:      #{actual.inspect}
                      MSG
  end

  def assert_contains_sub
    actual = result.value!

    if RSpec::Matchers.is_a_matcher?(contained)
      expect(actual).to contained
    else
      expect(actual).to match(contained)
    end
  end

  def resolve_expected(arg)
    case arg
    when Symbol then send(arg)
    when Proc   then instance_exec(&arg)
    else             arg
    end
  end
end
