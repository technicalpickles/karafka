# frozen_string_literal: true

RSpec.describe_current do
  describe 'BaseError' do
    subject(:error) { described_class::BaseError }

    specify { expect(error).to be < StandardError }
  end

  describe 'NonMatchingRouteError' do
    subject(:error) { described_class::NonMatchingRouteError }

    specify { expect(error).to be < described_class::BaseError }
  end

  describe 'InvalidConfigurationError' do
    subject(:error) { described_class::InvalidConfigurationError }

    specify { expect(error).to be < described_class::BaseError }
  end

  describe 'MissingBootFileError' do
    subject(:error) { described_class::MissingBootFileError }

    specify { expect(error).to be < described_class::BaseError }
  end

  describe 'ForcefulShutdownError' do
    subject(:error) { described_class::ForcefulShutdownError }

    specify { expect(error).to be < described_class::BaseError }
  end

  describe 'TopicNotFoundError' do
    subject(:error) { described_class::TopicNotFoundError }

    specify { expect(error).to be < described_class::BaseError }
  end

  describe 'ConsumerGroupNotFoundError' do
    subject(:error) { described_class::ConsumerGroupNotFoundError }

    specify { expect(error).to be < described_class::BaseError }
  end

  describe 'CommandValidationError' do
    subject(:error) { described_class::CommandValidationError }

    specify { expect(error).to be < described_class::BaseError }
  end

  describe 'InvalidLicenseTokenError' do
    subject(:error) { described_class::InvalidLicenseTokenError }

    specify { expect(error).to be < described_class::BaseError }
  end

  describe 'InvalidRealOffsetUsageError' do
    subject(:error) { described_class::InvalidRealOffsetUsageError }

    specify { expect(error).to be < described_class::BaseError }
  end

  describe 'InvalidTimeBasedOffsetError' do
    subject(:error) { described_class::InvalidTimeBasedOffsetError }

    specify { expect(error).to be < described_class::BaseError }
  end
end
