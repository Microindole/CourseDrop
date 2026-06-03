# 数据模型

CourseDrop 当前定位为本地优先的加密文件投递与分享管理工具。模型层围绕临时分享、群组文件流、传输任务、本地库、身份和设备组织。

## 客户端核心模型

### ShareSession

一次临时分享会话。它可以走公网中转，后续也可以和局域网直传策略协作。

字段：

- `id`：分享会话 ID。
- `title`：分享标题。
- `code`：分享码。
- `shareUrl`：公网分享链接，可以为空。
- `status`：`DRAFT`、`ACTIVE`、`REVOKED`、`EXPIRED`。
- `networkMode`：`LAN`、`RELAY`、`E2EE`、`OFFLINE`。
- `expireStatus`：`ACTIVE`、`EXPIRING_SOON`、`EXPIRED`。
- `createdAt`：创建时间。
- `expiresAt`：过期时间。
- `itemCount`：文件数量。
- `totalSizeBytes`：总大小。
- `encrypted`：是否加密。
- `downloadPolicy`：`PUBLIC`、`LOGIN_REQUIRED`、`OWNER_ONLY`。
- `items`：分享包含的传输项。

### TransferItem

分享或投递中的内容项。文件、图片、文本、链接都归一到这个模型。

字段：

- `id`：传输项唯一 ID。
- `roomId`：旧版房间 ID，可为空。
- `sessionId`：所属分享会话 ID，可为空。
- `type`：`FILE`、`IMAGE`、`TEXT`、`LINK`。
- `displayName`：展示名称。
- `contentType`：MIME 类型。
- `sizeBytes`：大小。
- `localUri`：本地文件 URI，可以为空。
- `remoteUrl`：公网临时副本地址，可以为空。
- `remoteItemId`：服务端分享项 ID，可以为空。
- `createdAt`：创建时间。
- `expiresAt`：过期时间。
- `encrypted`：是否端到端加密。

### GroupSession

客户端本地加入的加密群组。

字段：

- `id`：群组 ID。
- `encryptedName`：服务端保存的密文群名。
- `nameIv`：群名加密 IV。
- `nameAuthTag`：群名 AES-GCM tag。
- `plainName`：本地解密后的群名。
- `creatorId`：创建者设备指纹 ID。
- `joinedAt`：本机加入时间。
- `status`：`ACTIVE`、`ARCHIVED`、`DISBANDED`。
- `groupKeyMaterial`：本地保存的群组 AES key，不能上传服务端。
- `config`：群组配置。
- `lastMessageAt`：最近消息时间，可为空。
- `syncCursor`：消息同步游标，可为空。

### GroupMember

群组成员关系。

字段：

- `groupId`：群组 ID。
- `fingerprintId`：成员设备指纹 ID。
- `role`：`OWNER`、`MEMBER`。
- `status`：`ACTIVE`、`LEFT`、`REMOVED`。
- `joinedAt`：加入时间。
- `leftAt`：离开时间，可以为空。

### GroupMessage

群组密文消息外壳。服务端只保存外壳和密文 payload。

字段：

- `id`：消息 ID。
- `groupId`：群组 ID。
- `senderId`：发送者设备指纹 ID。
- `type`：`FILE`、`TEXT`、`CONTROL`。
- `createdAt`：创建时间。
- `iv`：payload 加密 IV。
- `authTag`：payload AES-GCM tag。
- `encryptedPayload`：密文 payload。
- `deliveryStatus`：本地投递状态，可为空。

### PlainFilePayload

群组 `FILE` 消息解密后的明文 payload。该 payload 会被 group key 加密后再上传。

字段：

- `fileId`：服务端群组文件 ID。
- `displayName`：明文文件名。
- `type`：文件类型。
- `contentType`：MIME 类型。
- `sizeBytes`：密文大小。
- `plainSizeBytes`：明文大小，可以为空。
- `sha256`：密文 hash。
- `encryptionAlgorithm`：文件加密算法。
- `kdfAlgorithm`：KDF 算法。
- `kdfSalt`：KDF salt。
- `fileKeyMaterial`：文件解密 key，只存在于群组密文 payload 内。
- `fileNonce`：文件加密 nonce。
- `fileAuthTag`：文件 AES-GCM tag。
- `expiresAt`：文件过期时间。

### Device

局域网或已发现设备。

字段：

- `id`：设备 ID。
- `name`：设备显示名。
- `platform`：设备平台。
- `status`：`ONLINE`、`IDLE`、`OFFLINE`。
- `networkMode`：当前连接方式。
- `latencyMs`：局域网延迟，可以为空。
- `lastSeenAt`：最后发现时间。

### TransferTask

上传、下载或局域网直传任务。

字段：

- `id`：任务 ID。
- `itemId`：关联传输项 ID。
- `direction`：`UPLOAD`、`DOWNLOAD`、`SEND`、`RECEIVE`。
- `status`：`PENDING`、`RUNNING`、`COMPLETED`、`FAILED`、`CANCELED`。
- `progress`：0 到 100 的进度。
- `speedBytesPerSecond`：传输速度，可以为空。
- `errorMessage`：失败原因，可以为空。

### LocalFileEntry

本地分享管理器中的文件项。

字段：

- `id`：本地记录 ID。
- `displayName`：展示名称。
- `type`：文件类型。
- `contentType`：MIME 类型。
- `sizeBytes`：大小。
- `localUri`：本地 URI。
- `lastSharedAt`：上次分享时间，可以为空。
- `shareCount`：分享次数。
- `remoteCached`：公网临时副本是否仍存在。
- `encrypted`：是否加密。

## 服务端身份模型

### DeviceFingerprint

设备指纹是服务端识别手机端的底层身份。

字段：

- `id`：设备指纹记录 ID。
- `fingerprint`：设备指纹摘要。
- `deviceName`：设备显示名。
- `platform`：平台。
- `accountId`：绑定账号 ID，可以为空。
- `createdAt`：创建时间。
- `lastSeenAt`：最后出现时间。

### Account

账号用于把多个设备指纹归并为同一个用户身份。

字段：

- `id`：账号 ID。
- `username`：账号名。
- `passwordHash`：密码摘要，可以为空。
- `passwordSalt`：密码盐，可以为空。
- `passwordAlgorithm`：密码哈希算法，可以为空。
- `passwordLoginEnabled`：是否允许账号密码登录。
- `createdAt`：创建时间。

默认登录方式是手机扫码。账号密码登录只有在用户主动开启后才允许。

### WebLoginSession

Web 管理端登录会话。

字段：

- `id`：会话 ID。
- `loginCode`：二维码登录码。
- `accountId`：登录账号 ID，可以为空。
- `fingerprintId`：确认登录的手机设备指纹 ID。
- `cookieTokenHash`：浏览器会话 Cookie 的服务端摘要，可以为空。
- `status`：`PENDING`、`CONFIRMED`、`EXPIRED`。
- `createdAt`：创建时间。
- `expiresAt`：过期时间。

## 服务端分享模型

### ServerShareSession

服务端公网分享会话。它只表示有效期内的临时中转，不表示永久文件夹。

字段：

- `id`：分享会话 ID。
- `code`：分享码。
- `ownerIdentityId`：设备指纹或账号身份。
- `ownerIdentityType`：`FINGERPRINT`、`ACCOUNT`、`ANONYMOUS`。
- `status`：`ACTIVE`、`EXPIRED`、`REVOKED`。
- `downloadPolicy`：`PUBLIC`、`LOGIN_REQUIRED`、`OWNER_ONLY`。
- `downloadAuthRequired`：旧客户端兼容字段。
- `createdAt`：创建时间。
- `expiresAt`：过期时间。

### ServerShareItem

服务端分享项。

字段：

- `id`：分享项 ID。
- `shareId`：所属分享 ID。
- `displayName`：展示名称。
- `contentType`：MIME 类型。
- `sizeBytes`：密文或文件大小。
- `storageKey`：服务器临时存储 key。
- `encrypted`：是否为端到端加密密文。
- `encryptionAlgorithm`：加密算法，可以为空。
- `kdfAlgorithm`：密钥派生算法，可以为空。
- `kdfSalt`：密钥派生盐，可以为空。
- `nonce`：加密 nonce/iv，可以为空。
- `sha256`：文件摘要。
- `plainSizeBytes`：明文大小，可以为空。
- `createdAt`：创建时间。
- `expiresAt`：过期时间。

## 服务端群组模型

### ServerGroupSession

字段：

- `id`：群组 ID。
- `encryptedName`：密文群名。
- `nameIv`：群名加密 IV。
- `nameAuthTag`：群名 AES-GCM tag。
- `creatorId`：创建者设备指纹 ID。
- `status`：`ACTIVE`、`ARCHIVED`、`DISBANDED`。
- `configJson`：群组配置 JSON。
- `createdAt`：创建时间。

### ServerGroupMember

字段：

- `groupId`：群组 ID。
- `fingerprintId`：成员设备指纹 ID。
- `role`：`OWNER`、`MEMBER`。
- `status`：`ACTIVE`、`LEFT`、`REMOVED`。
- `joinedAt`：加入时间。
- `leftAt`：离开时间，可以为空。

### ServerGroupMessage

字段：

- `id`：消息 ID。
- `groupId`：群组 ID。
- `senderId`：发送者设备指纹 ID。
- `type`：`FILE`、`TEXT`、`CONTROL`。
- `iv`：payload IV。
- `authTag`：payload tag。
- `encryptedPayload`：密文 payload。
- `createdAt`：创建时间。

### ServerGroupFile

字段：

- `id`：文件 ID。
- `groupId`：群组 ID。
- `uploaderId`：上传者设备指纹 ID。
- `storageKey`：服务器临时存储 key。
- `contentType`：MIME 类型。
- `sizeBytes`：密文大小。
- `encrypted`：是否加密。
- `encryptionAlgorithm`：文件加密算法。
- `kdfAlgorithm`：KDF 算法。
- `kdfSalt`：KDF salt。
- `nonce`：文件 nonce/tag。
- `sha256`：密文 hash。
- `plainSizeBytes`：明文大小。
- `createdAt`：创建时间。
- `expiresAt`：过期时间。

服务端群组模型不保存群组 key、文件 key、明文群名、明文消息和明文文件。

## 兼容模型

当前服务端仍保留早期房间模型：

- `Room`
- 旧版 `TransferItem.roomId`

后续客户端页面优先使用 `ShareSession` 和 `GroupSession`。
