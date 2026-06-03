# Java 服务端

CourseDrop 的 Java Spring Boot 服务端，负责公网限时中转、浏览器下载、设备指纹身份、扫码登录、加密群组文件流和过期清理。早期房间接口仍保留为兼容层。

## 技术栈

- Java 17
- Spring Boot 3
- Thymeleaf
- Tailwind CDN
- SQLite
- MyBatis-Plus
- 本地磁盘文件存储
- Maven

## 当前模块

```text
controller/ HTTP 接口入口
dto/        请求、响应和页面数据对象
enums/      业务枚举
service/    业务逻辑编排
mapper/     MyBatis-Plus 数据访问
entity/     数据库实体
common/     通用异常和错误响应
config/     配置、数据库初始化

auth/       Web 扫码登录内部会话对象
group/      群组文件流内部记录
share/      公网限时分享内部记录
storage/    本地文件存储
security/   密码哈希等安全工具
room/       早期房间兼容模型
transfer/   早期传输兼容模型
```

## 运行

```powershell
mvn test
mvn spring-boot:run
```

默认端口：

```text
8080
```

默认配置：

```text
src/main/resources/application.yml
```

## 当前已实现能力

- 服务首页、健康检查、能力查询和通用二维码生成。
- 设备指纹、账号创建、账号登录绑定、账号安全设置、设备绑定和解绑。
- Web 扫码登录、二维码、Cookie 签发、密码例外登录、退出、撤销和会话列表。
- 公网分享创建、上传、下载、撤回、续期、删除单项、审计和管理查询。
- 浏览器下载页 `/s/{code}`，支持扫码登录、账号密码例外登录和 WebCrypto 本地解密基础能力。
- App 下载接口支持设备指纹或账号身份鉴权。
- 端到端加密元数据校验：服务端只保存密文、算法、nonce/tag、hash、明文大小等，不接收 file key。
- 群组文件流 MVP：
  - 创建群、获取群、加入群、退出群。
  - 发送密文消息、按 cursor 同步密文消息。
  - 上传群组密文文件、成员下载密文文件。
  - 非成员拒绝访问。
  - 群组文件过期清理接入 `CleanupService`。
- 数据库初始化使用带 `schema_migrations` 的轻量迁移服务。
- 孤儿文件清理会保护旧版 transfer、share、group 三类 storage key。

## 群组接口

群组接口使用 `/api/groups`：

```text
POST   /api/groups
GET    /api/groups/{groupId}
POST   /api/groups/{groupId}/join
DELETE /api/groups/{groupId}/members/me
POST   /api/groups/{groupId}/messages
GET    /api/groups/{groupId}/messages
POST   /api/groups/{groupId}/files
GET    /api/groups/{groupId}/files/{fileId}/download
```

群组密钥不上传服务端。服务端只保存密文群名、密文消息、密文文件和必要元数据。

## 验证

当前服务端测试覆盖健康检查、分享主流程、账号安全、扫码 Cookie、加密元数据、分享管理和群组文件流。

```powershell
mvn test
```

最近验证结果：

```text
Tests run: 19, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

## 后续增强

- 群组消息 cursor 从 `createdAt` 升级为服务端递增序号。
- 群组成员管理：移除成员、解散群组、密钥轮换。
- 生产部署建议继续接入 Flyway/Liquibase、Redis 限流或网关限流。
