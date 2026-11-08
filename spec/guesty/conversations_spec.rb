RSpec.describe Guesty::Conversations do
  describe '.channel' do
    context 'with a module type in CHANNELS' do
      it 'returns its booking channel' do
        expect(described_class.channel('airbnb2')).to eq('airbnb')
        expect(described_class.channel('bookingCom')).to eq('booking_com')
      end
    end

    context 'with another module type' do
      it 'drops the version suffix' do
        expect(described_class.channel('homeaway2')).to eq('homeaway')
        expect(described_class.channel('whatsapp')).to eq('whatsapp')
      end
    end
  end
end
