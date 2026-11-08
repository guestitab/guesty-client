# Operations run as Op.new.call/Op.new.call! — stub them by injecting an
# instance through the class's `new`. Memoized per class per example so
# allow/expect pairs address the same double.
module OperationStubs
  # Verifying double for stubbing #call/#call! results.
  def operation_stub(klass)
    operation_stubs[klass] ||= instance_double(klass).tap do |double|
      allow(klass).to receive(:new).and_return(double)
      next unless klass.method_defined?(:call!)

      allow(double).to receive(:call!) do |*args, **kwargs|
        result = double.call(*args, **kwargs)

        raise result.failure if result.failure?

        result
      end
    end
  end

  # Real instance (partial double) — for and_call_original/and_wrap_original.
  def operation_spy(klass)
    operation_stubs[klass] ||= klass.new.tap do |instance|
      allow(klass).to receive(:new).and_return(instance)
    end
  end

  private

  def operation_stubs
    @operation_stubs ||= {}
  end
end

RSpec.configure do |config|
  config.include OperationStubs
end
