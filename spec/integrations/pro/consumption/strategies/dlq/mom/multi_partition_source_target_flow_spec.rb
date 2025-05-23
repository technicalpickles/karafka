# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# Same as pure DLQ version until rebalance

setup_karafka(allow_errors: %w[consumer.consume.error])

class Consumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      DT[:partitions] << message.partition
    end

    raise StandardError
  end
end

class DlqConsumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      DT[:broken] << message.partition
    end
  end
end

draw_routes do
  topic DT.topics[0] do
    config(partitions: 10)
    consumer Consumer
    dead_letter_queue(topic: DT.topics[1], max_retries: 0)
    manual_offset_management true
  end

  topic DT.topics[1] do
    config(partitions: 10)
    consumer DlqConsumer
    manual_offset_management true
  end
end

10.times do |i|
  elements = DT.uuids(100)
  produce_many(DT.topic, elements, partition: i)
end

start_karafka_and_wait_until do
  DT[:partitions].uniq.size >= 2 &&
    DT[:broken].uniq.size >= 5
end

# No need for any assertions as if it would pipe only to one, it would hang and crash via timeout
