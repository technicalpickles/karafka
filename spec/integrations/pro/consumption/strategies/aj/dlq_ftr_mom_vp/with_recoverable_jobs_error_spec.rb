# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# Karafka should recover from this error and move on without publishing anything to the DLQ
# Throttling should not impact order, etc

setup_active_job

setup_karafka(allow_errors: true) do |config|
  config.max_messages = 10
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
    raise StandardError if DT[0].size < 10
  end
end

draw_routes do
  active_job_topic DT.topic do
    manual_offset_management true
    # We set it to 100k so it never reaches it and always recovers
    dead_letter_queue topic: DT.topics[1], max_retries: 100_000
    virtual_partitions(
      partitioner: ->(_) { rand(10) }
    )
  end

  topic DT.topics[1] do
    consumer DlqConsumer
  end
end

5.times { |value| Job.perform_later(value) }

start_karafka_and_wait_until do
  DT[0].size >= 10
end

assert DT[1].empty?
