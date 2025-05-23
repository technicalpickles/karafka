# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# When running lrj, Karafka should never run the shutdown operations while consumption is in
# progress

setup_karafka do |config|
  config.max_messages = 1
  # We set it here that way not too wait too long on stuff
  config.kafka[:'max.poll.interval.ms'] = 10_000
  config.kafka[:'session.timeout.ms'] = 10_000
end

class Consumer < Karafka::BaseConsumer
  def consume
    sleep(15)

    DT[0] << Time.now
  end

  def shutdown
    DT[1] << Time.now
  end
end

draw_routes do
  topic DT.topic do
    consumer Consumer
    long_running_job true
    manual_offset_management true
    throttling(limit: 1_000_000, interval: 100_000)
  end
end

produce_many(DT.topic, DT.uuids(5))

start_karafka_and_wait_until do
  DT.key?(0)
end

assert DT[0].last < DT[1].last
assert_equal 0, fetch_next_offset
