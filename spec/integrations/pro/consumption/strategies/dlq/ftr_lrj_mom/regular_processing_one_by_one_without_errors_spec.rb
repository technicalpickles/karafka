# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# Karafka should be able to just process all the messages one after another

setup_karafka(allow_errors: true) do |config|
  config.max_messages = 1
end

class Consumer < Karafka::BaseConsumer
  def consume
    DT[0] << true
  end
end

draw_routes do
  topic DT.topic do
    consumer Consumer
    max_messages 1
    dead_letter_queue topic: DT.topics[1], max_retries: 4
    long_running_job true
    manual_offset_management true
    throttling(limit: 5, interval: 5_000)
  end
end

produce_many(DT.topic, DT.uuids(5))

start_karafka_and_wait_until do
  DT[0].size >= 5
end

assert DT[0].size >= 5
