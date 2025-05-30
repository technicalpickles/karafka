# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

RSpec.describe_current do
  subject(:max_epoch) { described_class.new }

  let(:grace_period) { 3_600 }

  describe '#initialize' do
    it 'starts with a max value of -1' do
      expect(max_epoch.to_i).to eq(-1)
    end
  end

  describe '#update' do
    context 'when new_max is greater than the current max' do
      it 'updates the max value to new_max' do
        max_epoch.update(10)
        expect(max_epoch.to_i).to eq(10 - grace_period)
      end

      it 'does not update the max value if new_max is not greater' do
        max_epoch.update(10)
        max_epoch.update(5)
        expect(max_epoch.to_i).to eq(10 - grace_period)
      end
    end

    context 'when new_max is equal to the current max' do
      it 'does not update the max value' do
        max_epoch.update(10)
        max_epoch.update(10)
        expect(max_epoch.to_i).to eq(10 - grace_period)
      end
    end
  end

  describe '#to_i' do
    context 'when no updates have been made' do
      it 'returns the initial value of -1' do
        expect(max_epoch.to_i).to eq(-1)
      end
    end

    context 'when updates have been made' do
      it 'returns the maximum value after updates' do
        max_epoch.update(100)
        expect(max_epoch.to_i).to eq(100 - grace_period)
        max_epoch.update(200)
        expect(max_epoch.to_i).to eq(200 - grace_period)
      end
    end
  end
end
