# Operations run as Op.new.call/Op.new.call!. operation_stub(Op) makes `new`
# return a verifying double, memoized per class per example so allow/expect
# pairs address the same double; its #call! unwraps the stubbed #call.
module OperationStubs
  def operation_stub(klass)
    operation_stubs[klass] ||= instance_double(klass).tap do |double|
      allow(klass).to receive(:new).and_return(double)
      allow(double).to receive(:call!) { |*args, **kwargs| double.call(*args, **kwargs).tap { raise it.failure if it.failure? } }
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
