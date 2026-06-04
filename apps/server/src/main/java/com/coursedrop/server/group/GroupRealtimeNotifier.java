package com.coursedrop.server.group;

import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import com.fasterxml.jackson.databind.ObjectMapper;

@Component
public class GroupRealtimeNotifier {
    private final ObjectMapper objectMapper;
    private final ConcurrentHashMap<String, Set<WebSocketSession>> sessionsByFingerprint = new ConcurrentHashMap<>();

    public GroupRealtimeNotifier(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public void register(String fingerprintId, WebSocketSession session) {
        sessionsByFingerprint.computeIfAbsent(fingerprintId, _key -> ConcurrentHashMap.newKeySet()).add(session);
    }

    public void unregister(String fingerprintId, WebSocketSession session) {
        var sessions = sessionsByFingerprint.get(fingerprintId);
        if (sessions == null) {
            return;
        }
        sessions.remove(session);
        if (sessions.isEmpty()) {
            sessionsByFingerprint.remove(fingerprintId);
        }
    }

    public void notifyMembers(List<String> fingerprintIds, GroupRealtimeEvent event) {
        String payload;
        try {
            payload = objectMapper.writeValueAsString(event);
        } catch (IOException error) {
            return;
        }
        fingerprintIds.forEach(fingerprintId -> sendToFingerprint(fingerprintId, payload));
    }

    private void sendToFingerprint(String fingerprintId, String payload) {
        var sessions = sessionsByFingerprint.get(fingerprintId);
        if (sessions == null) {
            return;
        }
        sessions.removeIf(session -> !send(session, payload));
    }

    private boolean send(WebSocketSession session, String payload) {
        if (!session.isOpen()) {
            return false;
        }
        try {
            session.sendMessage(new TextMessage(payload));
            return true;
        } catch (IOException error) {
            return false;
        }
    }
}
