# 系统设计

## 总体结构

```text
鸿蒙 ArkTS 客户端
        |
        | REST：分享、上传、下载、身份、扫码登录、群组文件流
        |
Java Spring Boot 服务端
        |
        | 元数据
        v
SQLite
        |
        | 临时密文/文件
        v
服务器本地磁盘
```

CourseDrop 的服务端只做限时中转、身份授权、密文消息同步和过期清理。文件加密、密钥保存、下载后解密和本地库管理由客户端完成。

## 当前实现策略

当前主线分两类：

```text
临时分享文件流：
本地库 -> 分享草稿 -> 公网分享 -> 上传密文/文件 -> 浏览器/App 下载 -> 清理

群组文件流：
创建群 -> 加入成员 -> 上传密文文件 -> 发送密文消息 -> 同步消息 -> 下载解密
```

局域网发现已有服务边界，但文件直传协议仍未完成。WebSocket 暂缓，当前群组消息同步使用 REST polling/cursor。

## Monorepo 结构

```text
apps/
  harmony/   鸿蒙原生客户端
  server/    Java Spring Boot 服务端
packages/
  api-contract/  REST 和事件契约
docs/
  agent/         Agent 接手指南
  api/           接口文档
  architecture/  架构和数据模型
  product/       产品说明和路线图
deploy/          部署配置
scripts/         本地脚本
```

## 服务端模块

服务端按业务域和分层组织：

```text
common/     通用异常和返回处理
config/     配置、数据库初始化
controller/ HTTP 入口
dto/        请求、响应和页面数据对象
entity/     MyBatis-Plus 表实体
enums/      业务枚举
mapper/     数据访问和仓储
service/    业务编排

auth/       Web 扫码登录内部对象
group/      群组文件流内部记录
share/      公网分享内部记录和分享码
storage/    本地文件存储
security/   密码哈希
room/       早期房间兼容模型
transfer/   早期传输兼容模型
```

核心服务：

- `ShareService`：公网限时分享、下载策略、撤回、续期、分享项和审计。
- `GroupService`：群组元数据、成员、密文消息、密文文件上传下载。
- `IdentityService`：设备指纹、账号、账号与设备绑定。
- `WebLoginService`：网页登录码、扫码确认、Cookie 会话。
- `CleanupService`：过期文件和孤儿文件清理。

## 客户端模块

```text
common/        配置、主题、Preferences、RDB
components/    通用 UI 组件和 CourseDrop 业务组件
entryability/  应用入口
models/        分享、传输、设备、本地库、身份、群组等模型
pages/         页面和独立测试页
services/      API、文件、加密、身份、分享、传输、扫码、局域网、群组等服务
viewmodels/    页面状态与业务编排
```

客户端页面不直接处理网络、文件系统或加密细节。页面调用 viewmodel，viewmodel 调用 service，service 再对接 REST、RDB、文件系统或 cryptoFramework。

## 加密边界

- 服务端可以保存密文、nonce/tag、算法、hash、明文大小等元数据。
- 服务端不能保存分享 file key、群组 group key、群组消息明文或文件明文。
- 分享密钥通过 URL fragment 或客户端本地流程传递。
- 群组密钥来自本地保存或邀请链接 fragment，群组消息 payload 由客户端用 group key 加密。

## 当前暂缓

- 完整 WebSocket 实时推送。
- 完整聊天系统。
- 复杂群主管理和密钥轮换。
- 局域网文件直传协议。
