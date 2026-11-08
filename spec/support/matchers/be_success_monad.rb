RSpec::Matchers.define :be_success_monad do
  description { 'be a success monad' }
  failure_message do
    failure = actual.failure

    if failure.is_a?(StandardError)
      backtrace = failure.backtrace.present? ? failure.backtrace.first(5).join("\n") : '<empty>'

      'expected to be Success, but got Failure:' \
        "\n\n#{failure.class}: #{failure.message}" \
        "\n\nBacktrace:" \
        "\n#{backtrace}"
    else
      "expected to be Success, but got Failure: #{failure.inspect}"
    end
  end

  match(&:success?)
end
