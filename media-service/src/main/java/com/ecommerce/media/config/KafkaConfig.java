package com.ecommerce.media.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

/**
 * Kafka Configuration for Media Service
 * 
 * Creates topics if they don't exist.
 */
@Configuration
public class KafkaConfig {

    @Value("${kafka.topics.image-uploaded}")
    private String imageUploadedTopic;

    @Value("${kafka.topics.image-deleted}")
    private String imageDeletedTopic;

    @Bean
    public NewTopic imageUploadedTopic() {
        return TopicBuilder.name(imageUploadedTopic)
                .partitions(3)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic imageDeletedTopic() {
        return TopicBuilder.name(imageDeletedTopic)
                .partitions(3)
                .replicas(1)
                .build();
    }
}
