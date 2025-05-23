# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# When a job is marked as lrj and a partition is lost, we should be able to get info about this
# by calling the `#revoked?` method.

setup_karafka do |config|
  config.max_messages = 10
  config.max_wait_time = 5_000
  # We set it here that way not too wait too long on stuff
  config.kafka[:'max.poll.interval.ms'] = 10_000
  config.kafka[:'session.timeout.ms'] = 10_000
  config.concurrency = 10
  config.shutdown_timeout = 120_000
  config.initial_offset = 'latest'
end

class Consumer < Karafka::BaseConsumer
  def consume
    DT[:owned] << messages.metadata.partition

    messages.each do
      sleep(0.1) while !revoked? && DT[:revoked].size < 2

      DT[:revoked] << messages.metadata.partition
    end
  end
end

draw_routes do
  topic DT.topic do
    config(partitions: 2)
    consumer Consumer
    long_running_job true
  end
end

thread = Thread.new do
  sleep(0.1) until Karafka::App.running?

  until DT[:revoked].uniq.size >= 2
    sleep(10)
    # We need a second producer to trigger a rebalance
    consumer = setup_rdkafka_consumer
    consumer.subscribe(DT.topic)
    5.times { consumer.poll(1_000) }
    consumer.close
  end
end

Thread.new do
  sleep(0.1) until Karafka::App.running?

  5.times do
    10.times do
      produce(DT.topic, '1', partition: 0)
      produce(DT.topic, '1', partition: 1)
    rescue StandardError
      nil
    end

    sleep(5)
  end
end

start_karafka_and_wait_until do
  DT[:revoked].uniq.size >= 2
end

# Many partitions should be revoked
assert_equal [0, 1], DT[:revoked].uniq.sort.to_a

thread.join
