# 服务端中转与身份设计

CourseDrop 服务端不是网盘，也不是完整聊天后端。服务端只负责在有效期内保存中转内容、提供下载入口、维护设备指纹与账号映射、同步群组密文消息，并在过期或撤回后删除服务器副本。

## 服务端职责

- 保存有效期内的公网中转文件。
- 为分享生成浏览器可打开的下载页面或直链。
- 支持 CourseDrop 手机端直接下载。
- 到期后删除分享记录、群组过期文件和对应文件。
- 维护设备指纹、账号、账号与设备指纹的绑定关系。
- 支持手机 CourseDrop 扫码登录 Web 管理端。
- 支持加密群组文件流的成员关系、密文消息和密文文件中转。

## 服务端不做

- 不做永久文件存储。
- 不做普通网盘目录。
- 不保存端到端加密明文密钥。
- 不保存群组 key 或 file key。
- 不保存群名明文、群组消息明文或群组文件明文。
- 不把账号密码登录作为默认入口暴露给普通用户。
- 不做完整 IM 聊天系统。

## 分享与下载

一次公网分享由一个 `ShareSession` 表示，包含多个 `ShareItem`。

```text
手机 CourseDrop
  -> 创建分享
  -> 上传密文/文件
  -> 服务端返回分享码和下载 URL
  -> 二维码编码下载 URL
  -> 浏览器或 CourseDrop App 下载
```

下载入口分两类：

- 浏览器下载：访问公开下载页面，按策略完成登录或扫码授权后下载。
- App 下载：CourseDrop 客户端携带设备指纹或账号身份下载。

服务端必须在每次下载前校验：

- 分享是否存在。
- 分享是否已过期。
- 分享是否已撤回。
- 当前访问者是否满足下载策略。
- 对应文件是否仍在服务器临时存储目录中。

## 群组文件流

群组由 `GroupSession`、`GroupMember`、`GroupMessage` 和 `GroupFile` 组成。

```text
发送端 CourseDrop
  -> 用 group key 加密 FILE payload
  -> 上传密文文件
  -> 发送密文消息

服务端
  -> 校验成员身份
  -> 保存密文消息和密文文件
  -> 不保存群组 key 和 file key

接收端 CourseDrop
  -> 同步密文消息
  -> 本地解密 payload
  -> 下载密文文件
  -> 本地解密入库
```

群组文件下载必须校验当前设备指纹是群组成员。非成员即使知道 `groupId` 和 `fileId` 也不能下载。

当前群组消息同步使用 REST cursor。`after` 暂时使用消息创建时间；后续可升级为服务端递增序号。

## 生命周期

分享生命周期：

```text
CREATED -> ACTIVE -> EXPIRED
        -> REVOKED
```

群组文件生命周期：

```text
UPLOADED -> ACTIVE -> EXPIRED
```

清理任务删除：

- 过期旧版 transfer 文件。
- 过期分享项和分享文件。
- 过期群组文件。
- 没有被旧版 transfer、share、group 引用的孤儿文件。

## 身份模型

CourseDrop 的身份以设备指纹为底层身份，账号是设备指纹之上的聚合身份。

```text
DeviceFingerprint
  -> 可以单独使用
  -> 可以绑定到 Account

Account
  -> 可以绑定多个 DeviceFingerprint
  -> 登录后服务端把设备指纹归并为账号身份
```

没有账号时，服务端按设备指纹识别用户。有账号时，服务端可以把已绑定指纹转换为账号身份。

账号不能替代手机指纹成为默认身份。账号只是在用户主动创建后，为跨设备和电脑登录提供便利。

## 下载策略

分享下载策略分三类：

```text
PUBLIC
  不登录也能下载。

LOGIN_REQUIRED
  任意已登录身份可下载。

OWNER_ONLY
  只有分享创建者的设备指纹或账号可下载。
```

`downloadAuthRequired` 只作为旧客户端兼容字段保留，新客户端应直接传 `downloadPolicy`。

## 端到端加密边界

服务端可以保存：

- `encrypted`
- `encryptionAlgorithm`
- `kdfAlgorithm`
- `kdfSalt`
- `nonce`
- `sha256`
- `plainSizeBytes`
- 密文文件
- 密文消息 payload

服务端绝不能保存：

- `fileKey`
- `groupKey`
- 明文文件
- 明文群名
- 明文消息
- 可直接恢复密钥的材料

## 后端模块方向

```text
controller/   HTTP 接口入口
dto/          Request、Response 和页面数据对象
enums/        业务枚举
service/      业务编排
mapper/       MyBatis-Plus 数据访问
entity/       数据库表实体
config/       应用配置、数据库初始化
common/       通用异常和错误响应

auth/         登录会话内部对象
group/        群组文件流内部记录
share/        公网分享内部记录和分享码生成
storage/      临时文件保存、读取、删除
security/     密码哈希等安全工具
room/         早期房间兼容模型
transfer/     早期传输兼容模型
```

当前 `room/transfer` 是早期兼容层，后续不再作为公网分享或群组文件流的主模型扩展。
