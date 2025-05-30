# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# When running jobs with recoverable errors, we should have the attempts count increased.
# We should NOT manage any offsets unless used manually.

setup_karafka(allow_errors: %w[consumer.consume.error]) do |config|
  config.max_messages = 20
end

class Consumer < Karafka::BaseConsumer
  def consume
    messages.each { |message| DT[0] << message.offset }

    DT[:attempts] << coordinator.pause_tracker.attempt
    DT[:raises] << true

    return unless (DT[:raises].size % 2).positive?

    raise(StandardError)
  end
end

draw_routes do
  topic DT.topic do
    consumer Consumer
    long_running_job true
    manual_offset_management true
    throttling(limit: 10, interval: 1_000)
    virtual_partitions(
      partitioner: ->(_msg) { rand(9) }
    )
  end
end

elements = DT.uuids(100)
produce_many(DT.topic, elements)

start_karafka_and_wait_until do
  DT[0].size >= 100
end

assert DT[:attempts].size >= 2, DT[:attempts]
assert_equal 0, fetch_next_offset
