# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# Karafka should auto-load all the routing features

setup_karafka

draw_routes(create_topics: false) do
  subscription_group do
    topic 'topic1' do
      consumer Class.new
      dead_letter_queue(topic: 'xyz', max_retries: 2)
      manual_offset_management true
      long_running_job true
    end
  end

  topic 'topic2' do
    consumer Class.new
  end
end

assert Karafka::App.consumer_groups.first.topics.first.dead_letter_queue?
assert Karafka::App.consumer_groups.first.topics.first.manual_offset_management?
assert Karafka::App.consumer_groups.first.topics.first.long_running_job?
assert !Karafka::App.consumer_groups.first.topics.last.dead_letter_queue?
assert !Karafka::App.consumer_groups.first.topics.last.manual_offset_management?
assert !Karafka::App.consumer_groups.first.topics.last.long_running_job?
