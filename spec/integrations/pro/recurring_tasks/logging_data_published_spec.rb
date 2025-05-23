# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

# When tasks are triggered, by default it should publish events to the logs topic
# This spec will hang if logs are not published

setup_karafka

class CountConsumer < Karafka::BaseConsumer
  def consume
    messages.each do |message|
      DT[:messages] << message.payload
    end
  end
end

draw_routes do
  recurring_tasks(true) do
    max_wait_time 500
  end

  topic Karafka::App.config.recurring_tasks.topics.logs.name do
    consumer CountConsumer
    deserializer Karafka::App.config.recurring_tasks.deserializer
  end
end

Karafka::Pro::RecurringTasks.define('1.0.0') do
  schedule(id: 'a', cron: '0 12 31 12 *', enabled: false) do
    DT[:a] = true
  end

  schedule(id: 'b', cron: '0 12 31 12 *', enabled: false) do
    DT[:b] = true
  end

  schedule(id: 'c', cron: '0 12 31 12 *', previous_time: Time.now - 120_000) do
    DT[:c] = true
  end
end

start_karafka_and_wait_until do
  unless @dispatched
    Karafka::Pro::RecurringTasks.trigger('*')
    @dispatched = true
  end

  DT[:messages].count >= 3
end

DT[:messages].each_with_index do |payload, i|
  assert_equal payload[:schema_version], '1.0'
  assert_equal payload[:schedule_version], '1.0.0'
  assert_equal payload[:type], 'log'
  assert payload[:dispatched_at].is_a?(Float)

  task = payload[:task]

  # Assertions for the task
  assert_equal task[:id], %w[a b c][i]
  assert task[:time_taken].is_a?(Float)
  assert_equal task[:result], 'success'
end
