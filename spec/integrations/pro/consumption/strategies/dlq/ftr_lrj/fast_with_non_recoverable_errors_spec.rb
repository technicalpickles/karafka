# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# Fast jobs should also not have any problems (though not recommended) when running as lrj

setup_karafka(allow_errors: %w[consumer.consume.error]) do |config|
  config.max_messages = 1
  # We set it here that way not too wait too long on stuff
  config.kafka[:'max.poll.interval.ms'] = 10_000
  config.kafka[:'session.timeout.ms'] = 10_000
end

class Consumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      DT[0] << message.offset
    end

    raise StandardError
  end
end

class DlqConsumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      DT[1] << [message.headers['source_offset'].to_i, message.offset]
    end
  end
end

draw_routes do
  topic DT.topic do
    consumer Consumer
    long_running_job true
    dead_letter_queue topic: DT.topics[1]
    throttling(limit: 5, interval: 5_000)
  end

  topic DT.topics[1] do
    consumer DlqConsumer
    throttling(limit: 5, interval: 5_000)
  end
end

payloads = DT.uuids(20)
produce_many(DT.topic, payloads)

start_karafka_and_wait_until do
  DT[0].size >= 20 && DT[1].size >= 10
end

# All messages moved to DLQ should have been present in the regular one
assert (DT[1].map(&:first) - DT[0]).empty?
# Each message should be present only once in the DLQ
assert_equal DT[1].uniq, DT[1]
# There should be many of them as we fail always
assert DT[1].size >= 10, DT[1]
