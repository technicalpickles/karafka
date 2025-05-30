# frozen_string_literal: true

# Karafka should work with Rails 7.1 that does not use ActiveJob using the default setup and should
# just ignore the ActiveJob components

# Load all the Railtie stuff like when `rails server`
ENV['KARAFKA_CLI'] = 'true'

Bundler.require(:default)

require 'tempfile'

class ExampleApp < Rails::Application
  config.eager_load = 'test'
end

dummy_boot_file = "#{Tempfile.new.path}.rb"
FileUtils.touch(dummy_boot_file)
ENV['KARAFKA_BOOT_FILE'] = dummy_boot_file

ExampleApp.initialize!

setup_karafka

class Consumer < Karafka::BaseConsumer
  def consume
    DT[0] << true
  end
end

draw_routes(Consumer)
produce(DT.topic, '1')

start_karafka_and_wait_until do
  DT.key?(0)
end

assert_equal 1, DT.data.size
assert Rails.version.starts_with?('7.1.')
