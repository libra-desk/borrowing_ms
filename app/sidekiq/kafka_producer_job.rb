require 'kafka'

class KafkaProducerJob 
  include Sidekiq::Job

  def perform(topic, message)
    kafka = Kafka.new(["127.0.0.1:9092"])
    producer = kafka.producer

    producer.produce(message.to_json, topic: topic) 
    producer.deliver_messages
  rescue => e
    Rails.logger.error("Kafka producer failed: #{e}")
  end
end
