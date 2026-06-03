# REST API 草案

基础地址：

```text
http://{server}:8080/api
```

## 房间

`/api/rooms` 是早期兼容接口。新的公网中转优先使用 `/api/shares`。

## 健康检查

### 查询中转源状态

```text
GET /api/health
GET /api/health/capabilities
```

返回：

```json
{
  "status": "UP",
  "service": "coursedrop-server",
  "time": "2026-05-25T12:00:00Z"
}
```

## 二维码

### 生成通用二维码 SVG

```text
GET /api/qr?text={url-or-payload}
```

用于客户端展示分享下载二维码。`text` 最大长度 1024，返回 `image/svg+xml`。

## 公网分享

### 创建分享

```text
POST /api/shares
```

请求体：

```json
{
  "expireHours": 24,
  "downloadPolicy": "LOGIN_REQUIRED"
}
```

新客户端应使用 `downloadPolicy`。`downloadAuthRequired` 仍作为旧客户端兼容字段保留；未传 `downloadPolicy` 时，服务端会把 `downloadAuthRequired=true` 映射为 `LOGIN_REQUIRED`，否则映射为 `PUBLIC`。

下载策略：

- `PUBLIC`：不登录也能下载。
- `LOGIN_REQUIRED`：任意已登录身份可下载，适合给别人发文件。
- `OWNER_ONLY`：只有创建者设备指纹或账号可下载，适合自己跨设备传输。

### 上传分享项

```text
POST /api/shares/{shareId}/items
Content-Type: multipart/form-data
```

表单字段：

- `file`：上传文件或密文文件
- `encrypted`：是否端到端加密
- `sha256`：文件摘要
- `encryptionAlgorithm`：加密算法，`encrypted=true` 时必填
- `kdfAlgorithm`：密钥派生算法，`encrypted=true` 时必填
- `kdfSalt`：密钥派生 salt，`encrypted=true` 时必填
- `nonce`：加密 nonce/iv，`encrypted=true` 时必填
- `plainSizeBytes`：明文大小，`encrypted=true` 时必填

### 获取分享下载页信息

```text
GET /api/shares/{code}
```

### 浏览器下载

```text
GET /s/{code}
GET /s/{code}/items/{itemId}/download
```

`PUBLIC` 分享可直接下载。`LOGIN_REQUIRED` 和 `OWNER_ONLY` 分享必须登录或通过手机扫码授权。

登录成功后服务端应签发 HttpOnly Cookie。后续浏览器下载请求通过 Cookie 校验身份，不应依赖前端可读 token。扫码是给当前电脑浏览器授权，授权后文件直接下载到电脑。

`OWNER_ONLY` 下载会校验 Cookie 绑定的账号或设备指纹是否匹配分享创建者。

端到端加密分享的推荐链接格式：

```text
GET /s/{code}#key={base64urlFileKey}
```

`#key` 不会发送给服务端，只由浏览器本地读取用于解密。禁止把密钥放在 query 参数中。

当前浏览器下载页已经支持基础本地解密：当分享项为 `encrypted=true` 且 URL 带有 `#key={base64urlFileKey}` 时，页面会使用 WebCrypto `AES-GCM` 在浏览器本地解密密文并保存明文文件。没有 `#key` 时仍下载密文文件。

### App 下载

```text
GET /api/shares/{code}/items/{itemId}/download
```

CourseDrop App 可携带设备指纹或账号会话下载：

- `X-CourseDrop-Fingerprint-Id`
- `X-CourseDrop-Account-Id`

手机 App 默认使用设备指纹身份，不要求账号。账号只在用户主动创建并绑定手机指纹后，用于账号密码登录或多设备归并。

### 撤回分享

```text
DELETE /api/shares/{shareId}
```

撤回后下载立即失效，服务器删除或等待清理任务删除临时文件。

### 查询和管理分享

```text
GET /api/shares?ownerIdentityId={id}&ownerIdentityType={type}
GET /api/shares?status=ACTIVE
POST /api/shares/{shareId}/expiry
DELETE /api/shares/{shareId}/items/{itemId}
```

用于查询我的分享、按状态筛选、续期和删除单个分享项。

## 身份与扫码登录

### 注册或刷新设备指纹

```text
POST /api/identity/fingerprints
```

### 创建账号并绑定当前手机指纹

```text
POST /api/accounts
```

账号创建发生在手机端安全设置中。创建后，当前手机设备指纹绑定到账号。默认仍可继续扫码登录；只有用户允许账号密码登录后，Web 才能使用账号密码登录。

如果账号名已存在，服务端返回 `409 Conflict`。App 不应继续重复创建，而应引导用户走“登录已有账号并绑定本机”。

### 登录已有账号并绑定当前手机指纹

```text
POST /api/accounts/login
```

请求体：

```json
{
  "username": "alice",
  "password": "secret",
  "fingerprintId": "device-fingerprint-id"
}
```

该接口只给 CourseDrop App 使用，用于“我已经有账号，现在把这台手机/模拟器绑定进账号”。它不受 Web 账号密码登录开关限制；`passwordLoginEnabled` 只限制浏览器端 `/api/auth/web-login/password`。服务端会校验：

- 账号存在且密码正确。
- `fingerprintId` 已注册。
- 当前指纹没有绑定到其他账号。

校验通过后，服务端把当前设备指纹绑定到该账号并返回 `AccountResponse`。如果账号或密码错误，返回 `401 Unauthorized`；如果指纹已绑定其他账号，返回 `409 Conflict`。

### 账号安全设置

```text
GET /api/accounts/{accountId}
POST /api/accounts/{accountId}/security
POST /api/accounts/{accountId}/password
GET /api/accounts/{accountId}/fingerprints
POST /api/accounts/{accountId}/fingerprints
DELETE /api/accounts/{accountId}/fingerprints/{fingerprintId}
```

用途：

- 查询账号状态。
- 开启或关闭账号密码登录。
- 修改账号密码。
- 查询账号绑定的设备指纹。
- 绑定新的设备指纹。
- 解绑已有设备指纹。

这些接口需要证明调用者能管理该账号。请求应携带其一：

- `X-CourseDrop-Account-Id`：必须等于路径中的 `{accountId}`。
- `X-CourseDrop-Fingerprint-Id`：该设备指纹必须已经绑定到路径中的 `{accountId}`。

`POST /api/accounts/{accountId}/security` 请求体：

```json
{
  "passwordLoginEnabled": true
}
```

`POST /api/accounts/{accountId}/password` 请求体：

```json
{
  "password": "new-password"
}
```

`POST /api/accounts/{accountId}/fingerprints` 请求体：

```json
{
  "fingerprintId": "device-fingerprint-id"
}
```

### 创建 Web 扫码登录会话

```text
POST /api/auth/web-login
```

返回二维码登录码。浏览器页面用该登录码生成二维码，并轮询登录状态。

### 手机确认 Web 登录

```text
POST /api/auth/web-login/{loginCode}/confirm
```

### 查询 Web 登录状态

```text
GET /api/auth/web-login/{loginCode}
```

确认成功后，服务端为浏览器写入 `CD_SESSION` HttpOnly Cookie。

### 获取 Web 登录二维码

```text
GET /api/auth/web-login/{loginCode}/qr.svg
```

返回可扫码的 QR SVG。二维码内容指向：

```text
GET /m/login/{loginCode}
```

没有鸿蒙真机时，可用安卓手机扫码打开该页面，输入 CourseDrop 设置页里的 `fingerprintId` 后确认网页登录。

### 手机浏览器确认页

```text
GET /m/login/{loginCode}
POST /m/login/{loginCode}
```

`POST` 表单字段：

- `fingerprintId`：手机端或模拟器注册到服务端后的设备指纹 ID。

该页面是开发和课程演示用入口。正式 App 仍应直接调用 `POST /api/auth/web-login/{loginCode}/confirm`。

### 账号密码登录

```text
POST /api/auth/web-login/password
```

账号密码登录默认不可见。只有用户在手机 CourseDrop 中关闭安全设置后才允许使用。

### Web 会话管理

```text
POST /api/auth/web-login/logout
DELETE /api/auth/web-login/{loginCode}
GET /api/auth/web-login/sessions?fingerprintId={id}
GET /api/auth/web-login/sessions?accountId={id}
```

用于退出当前浏览器会话、手机端撤销登录和查询会话列表。

### 查询分享删除审计

```text
GET /api/shares/{shareId}/audit
```

用于排查分享过期、撤回或清理失败原因。审计不返回文件内容。

## 群组文件流

群组接口用于 Telegram 式的加密群组文件投递。第一版只中继群组元数据和密文消息，服务器不保存群名明文、消息明文或群组密钥。

### 创建群组

```text
POST /api/groups
```

请求体：

```json
{
  "encryptedName": "base64url-ciphertext",
  "nameIv": "base64url-iv",
  "nameAuthTag": "base64url-tag",
  "creatorId": "device-fingerprint-id",
  "configJson": "{\"allowText\":false,\"expiryHours\":24,\"maxFileSizeMb\":100}"
}
```

### 获取群组密文元数据

```text
GET /api/groups/{groupId}
```

返回密文群名、创建者、状态和配置 JSON。群组密钥必须来自邀请链接 fragment 或本地安全存储，不会由服务端返回。

### 加入和退出群组

```text
POST /api/groups/{groupId}/join
DELETE /api/groups/{groupId}/members/me
```

加入请求体：

```json
{
  "fingerprintId": "device-fingerprint-id"
}
```

退出请求头：

```text
X-CourseDrop-Fingerprint-Id: device-fingerprint-id
```

### 发送密文群组消息

```text
POST /api/groups/{groupId}/messages
```

请求体：

```json
{
  "id": "client-message-uuid",
  "senderId": "device-fingerprint-id",
  "type": "FILE",
  "iv": "payload-iv",
  "authTag": "payload-auth-tag",
  "encryptedPayload": "payload-ciphertext"
}
```

### 同步群组消息

```text
GET /api/groups/{groupId}/messages?after={cursor}
```

请求头：

```text
X-CourseDrop-Fingerprint-Id: device-fingerprint-id
```

返回：

```json
{
  "messages": [],
  "nextCursor": "2026-06-03T09:00:00Z"
}
```

`after` 当前使用消息创建时间作为同步 cursor。后续如果需要更强顺序保证，可迁移为服务端递增序号。

### 上传群组密文文件

```text
POST /api/groups/{groupId}/files
Content-Type: multipart/form-data
```

请求头：

```text
X-CourseDrop-Fingerprint-Id: device-fingerprint-id
```

表单字段：

- `file`：密文文件
- `encrypted`：是否端到端加密，默认 `true`
- `encryptionAlgorithm`：加密算法，`encrypted=true` 时必填
- `kdfAlgorithm`：密钥派生算法，`encrypted=true` 时必填
- `kdfSalt`：密钥派生 salt，`NONE-RAW-KEY` 可为空
- `nonce`：文件加密 nonce/iv 与认证标签
- `sha256`：密文文件摘要
- `plainSizeBytes`：明文大小
- `expiryHours`：文件 TTL，可选，默认使用服务端 `file-ttl-hours`

服务器只保存密文文件和必要元数据，不保存文件名明文或文件密钥。文件名、MIME、file key 等面向用户的载荷应放入群组密文消息 `encryptedPayload`。

### 下载群组密文文件

```text
GET /api/groups/{groupId}/files/{fileId}/download
```

请求头：

```text
X-CourseDrop-Fingerprint-Id: device-fingerprint-id
```

只有当前群组成员可以下载。返回的是服务器保存的密文文件；客户端需要先同步对应 `FILE` 消息，解密 `encryptedPayload` 后拿到 file key，再在本地解密文件。

### 创建房间

```text
POST /api/rooms
```

请求体：

```json
{
  "name": "移动应用开发第 3 组"
}
```

### 加入房间

```text
POST /api/rooms/{code}/join
```

### 获取房间

```text
GET /api/rooms/{roomId}
```

## 传输项

### 查询房间传输项

```text
GET /api/rooms/{roomId}/items
```

### 上传文件

```text
POST /api/files/upload
Content-Type: multipart/form-data
```

表单字段：

- `roomId`：房间 ID
- `file`：上传文件

### 下载文件

```text
GET /api/files/{itemId}/download
```

## 后续接口

### 上传剪贴板片段

```text
POST /api/clipboard
```

### 查询剪贴板片段

```text
GET /api/clipboard?roomId={roomId}
```

### 删除传输项

```text
DELETE /api/items/{itemId}
```
