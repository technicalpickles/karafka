# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# When handling failing messages from a many partitions and there are many errors, DLQ will provide
# strong ordering warranties inside DLQ.

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
      DT["broken-#{message.partition}"] << message.headers['source_partition']
    end
  end
end

draw_routes do
  topic DT.topics[0] do
    config(partitions: 10)
    consumer Consumer
    dead_letter_queue(topic: DT.topics[1], max_retries: 0)
  end

  topic DT.topics[1] do
    config(partitions: 10)
    consumer DlqConsumer
  end
end

10.times do |i|
  elements = DT.uuids(100)
  produce_many(DT.topic, elements, partition: i)
end

start_karafka_and_wait_until do
  DT[:partitions].uniq.size >= 10 &&
    DT.data.keys.uniq.size >= 5
end

samples = {}

# Data from given original partition should only be present in one target partition
DT.data.each do |k, v|
  next if k == :partitions

  v.each do |source_partition|
    samples[source_partition] ||= []
    samples[source_partition] << k
  end
end

# Each original partition data should always go to one and the same target partition
samples.each_value do |sources|
  assert_equal 1, sources.uniq.size, sources
end
