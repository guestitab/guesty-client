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
