# frozen_string_literal: true

# When using multiple consumer groups and when one is rebalanced, it should not affect the one
# that was not a rebalance subject

setup_karafka do |config|
  config.concurrency = 5
end

class Consumer < Karafka::BaseConsumer
  def consume
    DT[:working] << [topic.name, messages.partition]
  end

  def on_revoked
    DT[messages.metadata.topic] << messages.metadata.partition
  end
end

draw_routes do
  consumer_group DT.consumer_groups[0] do
    topic DT.topics[0] do
      config(partitions: 2)
      consumer Consumer
    end
  end

  consumer_group DT.consumer_groups[1] do
    topic DT.topics[1] do
      config(partitions: 2)
      consumer Consumer
    end
  end
end

Thread.new do
  loop do
    2.times do |i|
      produce(DT.topics[i], '1', partition: 0)
      produce(DT.topics[i], '2', partition: 1)
    end

    sleep(1)
  rescue WaterDrop::Errors::ProducerClosedError
    break
  end
end

consumer = setup_rdkafka_consumer

other = Thread.new do
  sleep(1) while DT[:working].uniq.size < 2

  sleep(1)

  consumer.subscribe(DT.topics[0])

  consumer.each { break }

  consumer.close
end

start_karafka_and_wait_until do
  other.join

  true
end

# The second topic should not be rebalanced at all as it is in a different consumer group than
# the one that had a rebalance
assert !DT.data.key?(DT.topics[1])
