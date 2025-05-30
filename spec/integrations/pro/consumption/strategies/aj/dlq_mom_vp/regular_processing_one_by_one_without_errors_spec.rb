# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# Karafka should be able to just process all the jobs one after another
setup_active_job

setup_karafka(allow_errors: true) do |config|
  config.max_messages = 1
end

class Job < ActiveJob::Base
  queue_as DT.topic

  def perform(value)
    DT[0] << value
  end
end

draw_routes do
  active_job_topic DT.topic do
    max_messages 1
    dead_letter_queue topic: DT.topics[1], max_retries: 4
    virtual_partitions(
      partitioner: ->(_) { rand(10) }
    )
  end
end

5.times { |value| Job.perform_later(value) }

start_karafka_and_wait_until do
  DT[0].size >= 5
end

assert DT[0].size >= 5
