package com.coursedrop.server.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

import com.coursedrop.server.group.GroupWebSocketHandler;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
    private final GroupWebSocketHandler groupWebSocketHandler;

    public WebSocketConfig(GroupWebSocketHandler groupWebSocketHandler) {
        this.groupWebSocketHandler = groupWebSocketHandler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(groupWebSocketHandler, "/ws/groups")
                .setAllowedOrigins("*");
    }
}
