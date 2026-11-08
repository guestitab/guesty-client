RSpec.describe Guesty::ApiError do
  subject(:error) { described_class.new(instance_double(Faraday::Response, status:, body:)) }

  let(:status) { 422 }
  let(:body) { { error: { message: 'Request rejected' } } }

  it { is_expected.to have_attributes(status: 422, message: 'Request rejected', retryable_non_delivery?: false, permanent_rejection?: true) }

  context 'when Guesty tunnels the error status through an HTTP 200' do
    let(:status) { 200 }
    let(:body) { { status: '429', error: { message: 'Rate limit exceeded' } } }

    it { is_expected.to have_attributes(status: 429, retryable_non_delivery?: true, permanent_rejection?: false) }
  end

  context 'when Guesty answers a 403 glitch' do
    let(:status) { 403 }
    let(:body) { { error: { message: 'Forbidden err' } } }

    it { is_expected.to have_attributes(guesty_glitch?: true, retryable_non_delivery?: true, permanent_rejection?: false) }
  end

  context 'when Guesty answers 500' do
    let(:status) { 500 }
    let(:body) { { error: { message: 'Internal error' } } }

    it { is_expected.to have_attributes(retryable_non_delivery?: false, permanent_rejection?: false) }
  end

  context 'when Guesty relays an upstream 400' do
    let(:status) { 500 }
    let(:body) { { error: { code: 'HTTP_UPSTREAM_REQUEST_ERROR', message: 'Request failed with status code 400', data: {} } } }

    it { is_expected.to have_attributes(status: 400, retryable_non_delivery?: false, permanent_rejection?: true) }
  end

  context 'when Guesty relays an upstream 502' do
    let(:status) { 500 }
    let(:body) { { error: { code: 'HTTP_UPSTREAM_REQUEST_ERROR', message: 'Request failed with status code 502', data: {} } } }

    it { is_expected.to have_attributes(status: 502, permanent_rejection?: false) }
  end

  context 'when the error carries data' do
    let(:status) { 400 }
    let(:body) do
      { error: { status: 400, message: 'Duplicate approve/decline request', code: 'DUPLICATE_REQUEST', data: 'Approve/decline request already exists for this reservation' } }
    end

    it { is_expected.to have_attributes(message: 'Approve/decline request already exists for this reservation') }
  end
end
