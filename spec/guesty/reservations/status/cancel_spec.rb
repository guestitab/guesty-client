RSpec.describe Guesty::Reservations::Status::Cancel do
  include_context 'operations'

  let(:args) { { reservation_id:, note: 'Owner stay cancelled by Ownar Propertson', cancelled_by: } }

  let(:reservation_id) { '6a07388c47a7e7335fc6a203' }
  let(:cancelled_by) { :owner }

  context 'with valid arguments' do
    let(:update) { operation_stub(Guesty::Reservations::Status::Update) }

    before do
      allow(update).to receive(:call).and_return(Success(true))

      result
    end

    it_behaves_like 'successful call', value: true

    it 'calls Guesty::Reservations::Status::Update' do
      expect(update).to have_received(:call).with(
        reservation_id:,
        attributes: {
          status: 'canceled',
          cancellationReason: 'No Reason Provided',
          cancellationNote: 'Owner stay cancelled by Ownar Propertson',
          canceledBy: 'OWNER'
        }
      )
    end
  end

  context 'with invalid arguments' do
    context 'when cancelled_by is unknown' do
      let(:cancelled_by) { :channel }
      let(:message) { 'cancelled_by: invalid' }

      it_behaves_like 'failed call', failure_class: Guesty::ArgumentError
    end
  end
end
