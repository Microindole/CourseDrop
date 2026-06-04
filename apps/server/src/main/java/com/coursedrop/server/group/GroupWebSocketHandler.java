package com.coursedrop.server.group;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class GroupWebSocketHandler extends TextWebSocketHandler {
    private final GroupRealtimeNotifier notifier;

    public GroupWebSocketHandler(GroupRealtimeNotifier notifier) {
        this.notifier = notifier;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        var fingerprintId = resolveFingerprintId(session.getUri());
        if (fingerprintId.isBlank()) {
            session.close(CloseStatus.POLICY_VIOLATION);
            return;
        }
        session.getAttributes().put("fingerprintId", fingerprintId);
        notifier.register(fingerprintId, session);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        var fingerprintId = session.getAttributes().get("fingerprintId");
        if (fingerprintId instanceof String value && !value.isBlank()) {
            notifier.unregister(value, session);
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        if ("ping".equalsIgnoreCase(message.getPayload())) {
            session.sendMessage(new TextMessage("pong"));
        }
    }

    private String resolveFingerprintId(URI uri) {
        if (uri == null || uri.getQuery() == null) {
            return "";
        }
        var parts = uri.getQuery().split("&");
        for (String part : parts) {
            var separator = part.indexOf('=');
            if (separator < 0) {
                continue;
            }
            var key = decode(part.substring(0, separator));
            if ("fingerprintId".equals(key)) {
                return decode(part.substring(separator + 1));
            }
        }
        return "";
    }

    private String decode(String value) {
        return URLDecoder.decode(value, StandardCharsets.UTF_8);
    }
}
