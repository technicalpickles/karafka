# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# When using Virtual Partitions, we can distribute work in a way that allows us to gain granular
# control over what goes to a single virtual partition. We can create virtual partition based on
# any of the resource details

setup_karafka do |config|
  config.concurrency = 5
  config.max_messages = 500
  config.max_wait_time = 2_000
end

class Consumer < Karafka::BaseConsumer
  def consume
    DT[:objects_ids] << object_id
    DT[:messages] << messages.size
  end
end

draw_routes do
  topic DT.topics[0] do
    consumer Consumer

    # This combination will make a virtual partition per message. You probably don't want that
    # in a regular setup.
    virtual_partitions(
      max_partitions: 200,
      partitioner: ->(msg) { msg.raw_payload }
    )
  end
end

produce_many(DT.topics[0], DT.uuids(1_000))

start_karafka_and_wait_until do
  DT[:messages].sum >= 200
end

# The distribution is per batch and the first one is super small, so it won't be always 200, it
# may be less due to how we reduce it and the data sample
assert DT[:objects_ids].uniq.size > 100
