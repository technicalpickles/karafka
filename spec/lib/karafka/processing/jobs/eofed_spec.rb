# frozen_string_literal: true

RSpec.describe_current do
  subject(:job) { described_class.new(executor) }

  let(:executor) { build(:processing_executor) }

  before do
    allow(executor).to receive(:eofed)
    job.call
  end

  specify { expect(described_class.action).to eq(:eofed) }

  it { expect(job.id).to eq(executor.id) }
  it { expect(job.group_id).to eq(executor.group_id) }
  it { expect(job.non_blocking?).to be(false) }

  it 'expect to run eofed on the executor' do
    expect(executor).to have_received(:eofed)
  end

  describe '#before_schedule' do
    before do
      allow(executor).to receive(:before_schedule_eofed)
      job.before_schedule
    end

    it 'expect to run before_schedule_eofed on the executor' do
      expect(executor).to have_received(:before_schedule_eofed)
    end
  end
end
