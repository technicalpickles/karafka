# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# Same as pure DLQ version until rebalance

setup_karafka(allow_errors: %w[consumer.consume.error])

class Consumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      raise StandardError if message.offset == 99

      DT[:offsets] << message.offset

      mark_as_consumed message
    end
  end
end

class DlqConsumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      DT[:broken] << [message.offset, message.raw_payload]
    end
  end
end

draw_routes do
  topic DT.topics[0] do
    consumer Consumer
    dead_letter_queue(topic: DT.topics[1], max_retries: 2)
    manual_offset_management(true)
  end

  topic DT.topics[1] do
    consumer DlqConsumer
    manual_offset_management(true)
  end
end

Karafka.monitor.subscribe('error.occurred') do |event|
  next unless event[:type] == 'consumer.consume.error'

  DT[:errors] << 1
end

elements = DT.uuids(100)
produce_many(DT.topic, elements)

start_karafka_and_wait_until do
  # Send one more when we reached all
  if DT[:offsets].uniq.size == 99 && DT[:extra].empty?
    DT[:extra] << true
    produce(DT.topic, SecureRandom.hex(6))
  end

  DT[:offsets].uniq.size >= 100 && DT.key?(:broken)
end

# first error and two errors on retries prior to moving on
assert_equal 3, DT[:errors].size

# we should not have the message that was failing
assert_equal (0..100).to_a - [99], DT[:offsets]

assert_equal 1, DT[:broken].size
# This message will get new offset (first)
assert_equal DT[:broken][0][0], 0
assert_equal DT[:broken][0][1], elements[99]
