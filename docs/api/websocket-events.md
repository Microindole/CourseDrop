# WebSocket 事件草案

WebSocket 是实时通知层，不是可靠消息存储层。可靠历史仍由 REST cursor 同步保证。

当前群组实时入口：

```text
GET /ws/groups?fingerprintId={fingerprintId}
```

连接建立后，服务端按 `fingerprintId` 维护在线会话。发送群组消息时，服务端向群成员在线连接广播密文事件。

## 客户端发送

### join_room

加入房间实时通道。

```json
{
  "type": "join_room",
  "payload": {
    "roomId": "room-id",
    "deviceName": "MatePad"
  }
}
```

### heartbeat

设备心跳。

```json
{
  "type": "heartbeat",
  "payload": {
    "roomId": "room-id",
    "deviceId": "device-id"
  }
}
```

## 服务端发送

## 相关 REST 补拉接口

WebSocket 只负责提示有变化，客户端仍通过 REST 获取可靠状态：

- `GET /api/groups/{groupId}/messages?after={cursor}`：补拉群组密文消息。
- `GET /api/groups/{groupId}/members`：补拉群成员状态。
- `GET /api/groups/key-backups/mine`：登录账号后列出可恢复的密文群 key 备份。

### GROUP_MESSAGE_CREATED

群组内出现新的密文消息。

```json
{
  "type": "GROUP_MESSAGE_CREATED",
  "groupId": "group-id",
  "payload": {
    "id": "message-id",
    "groupId": "group-id",
    "senderId": "fingerprint-id",
    "type": "FILE",
    "iv": "payload-iv",
    "authTag": "payload-tag",
    "encryptedPayload": "ciphertext",
    "createdAt": "2026-06-04T08:00:00Z"
  }
}
```

鸿蒙端当前处理策略：

- 如果本地持有该群组 key，则触发该群 REST cursor 同步并刷新 UI。
- 如果事件丢失或客户端离线，则下次进入会话时通过 REST cursor 补拉。
- WebSocket 事件不包含明文内容、群组 key 或 file key。

### room_member_joined

有设备加入房间。

### item_created

房间内出现新的文件、图片、文本或链接。

### item_deleted

传输项被删除或过期清理。

### room_expiring

房间即将过期。
