# `value:` pins the exact value; `value_containing:` matches it against a
# matcher or a fuzzy Hash/Array. A Proc is evaluated in the example.
RSpec.shared_examples 'successful call' do |**expected|
  def resolve(expected) = expected.is_a?(Proc) ? instance_exec(&expected) : expected

  it 'succeeds with the expected value' do
    expect(result).to be_success_monad
    expect(result.value!).to eq(resolve(expected[:value])) if expected.key?(:value)
    expect(result.value!).to match(resolve(expected[:value_containing])) if expected.key?(:value_containing)
  end
end
