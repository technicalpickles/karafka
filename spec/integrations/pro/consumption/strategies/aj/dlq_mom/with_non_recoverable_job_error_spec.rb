# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# Karafka should run the same strategy for AJ DLQ MOM as for DLQ MOM.
#
# For AJ based workloads it means marking after each. This means, we will end up in a loop.
# This resembles a non MOM standard flow for DLQ (management of work is on AJ base) because
# from the end user perspective the offset management is not manual - it is delegated to the
# framework and realized via the ActiveJob consumer itself.

setup_active_job

setup_karafka(allow_errors: true) do |config|
  config.max_messages = 10
  config.kafka[:'max.poll.interval.ms'] = 10_000
  config.kafka[:'session.timeout.ms'] = 10_000
end

class DlqConsumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      DT[1] << message.headers['source_offset'].to_i
    end
  end
end

class Job < ActiveJob::Base
  queue_as DT.topic

  def perform(value)
    DT[0] << value
    sleep(value.to_f / 20)
    raise StandardError
  end
end

draw_routes do
  active_job_topic DT.topic do
    dead_letter_queue topic: DT.topics[1], max_retries: 4
    long_running_job true
    # mom is enabled automatically
  end

  topic DT.topics[1] do
    consumer DlqConsumer
  end
end

5.times { |value| Job.perform_later(value) }

start_karafka_and_wait_until do
  DT[0].size >= 10 && DT[1].size >= 5
end

# We should skip and continue processing with each job after 4 retries
DT[0][0..24].each_slice(5).with_index do |slice, index|
  assert_equal 1, slice.uniq.size
  assert_equal index, slice.first
end

assert_equal (0..4).to_a, DT.data[1]
