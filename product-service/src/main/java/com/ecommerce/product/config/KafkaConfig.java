package com.ecommerce.product.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

/**
 * Kafka Configuration for Product Service
 * 
 * Creates topics if they don't exist.
 */
@Configuration
public class KafkaConfig {

    @Value("${kafka.topics.product-created}")
    private String productCreatedTopic;

    @Value("${kafka.topics.product-updated}")
    private String productUpdatedTopic;

    @Value("${kafka.topics.product-deleted}")
    private String productDeletedTopic;

    @Value("${kafka.topics.image-uploaded}")
    private String imageUploadedTopic;

    @Bean
    public NewTopic productCreatedTopic() {
        return TopicBuilder.name(productCreatedTopic)
                .partitions(3)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic productUpdatedTopic() {
        return TopicBuilder.name(productUpdatedTopic)
                .partitions(3)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic productDeletedTopic() {
        return TopicBuilder.name(productDeletedTopic)
                .partitions(3)
                .replicas(1)
                .build();
    }
}
