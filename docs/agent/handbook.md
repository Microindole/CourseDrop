# Agent 接手指南

这份文档用于让新的 agent 或开发者快速接手 CourseDrop。

## 项目一句话

CourseDrop / 课递：本地优先的加密文件投递与分享管理工具。

## 当前重点

当前暂停功能主线，优先校准过时文档。文档校准后，下一条开发主线是鸿蒙端群组独立测试页：

```text
GroupTestPage -> 群组 API 联调 -> 群组文件加密上传 -> FILE 消息 -> 下载解密 -> 再接主流程
```

临时分享主线已经具备可联调闭环；群组功能第一版定位为“加密群组文件流”，不是完整 IM 聊天系统。

## 技术栈

- 客户端：HarmonyOS ArkTS / ArkUI
- 服务端：Java 17 + Spring Boot 3
- 数据库：SQLite
- 文件存储：服务器本地磁盘
- 数据访问：MyBatis-Plus

## 重要目录

```text
apps/harmony/   鸿蒙客户端
apps/server/    Java 服务端
docs/           中文文档
docs/deploy/    服务器部署和运维文档
packages/api-contract/  接口契约
.github/        GitHub Actions 工作流和可复用 action
```

## 服务端现状

Java server 已完成临时分享、身份、扫码登录、E2EE 元数据、浏览器下载页、App 下载和群组文件流 MVP。

关键文件：

- `apps/server/src/main/java/com/coursedrop/server/CourseDropApplication.java`
- `apps/server/src/main/java/com/coursedrop/server/controller/ShareController.java`
- `apps/server/src/main/java/com/coursedrop/server/controller/GroupController.java`
- `apps/server/src/main/java/com/coursedrop/server/service/ShareService.java`
- `apps/server/src/main/java/com/coursedrop/server/service/GroupService.java`
- `apps/server/src/main/java/com/coursedrop/server/service/CleanupService.java`
- `apps/server/src/main/java/com/coursedrop/server/storage/LocalFileStorageService.java`
- `apps/server/src/main/java/com/coursedrop/server/config/DatabaseMigrationService.java`

验证命令：

```powershell
cd D:\works\coursedrop\apps\server
mvn test
```

## 客户端现状

鸿蒙端已具备首页 Tab、本地库、分享、接收分享、设置、身份、中转源、E2EE、局域网发现边界和群组独立测试基础。

关键文件：

- `apps/harmony/entry/src/main/ets/pages/HomePage.ets`
- `apps/harmony/entry/src/main/ets/pages/SharePage.ets`
- `apps/harmony/entry/src/main/ets/pages/LocalLibraryPage.ets`
- `apps/harmony/entry/src/main/ets/pages/ShareDownloadPage.ets`
- `apps/harmony/entry/src/main/ets/pages/GroupTestPage.ets`
- `apps/harmony/entry/src/main/ets/services/group/`
- `apps/harmony/entry/src/main/ets/services/crypto/`
- `apps/harmony/entry/src/main/ets/services/transfer/`
- `apps/harmony/entry/src/main/ets/services/share/`

`GroupTestPage` 已注册路由但未接入首页或 Tab，用于独立联调。

## 下一步建议

详细任务见 `docs/agent/next-steps.md`。

建议顺序：

1. 保持文档与代码状态一致。
2. 用 Java server 跑通鸿蒙 `GroupTestPage`：身份注册、创建群、发密文消息、同步解密。
3. 在独立测试页补群组文件选择、AES-GCM 加密、上传、发送 `FILE` 消息、下载和解密。
4. 群组文件流稳定后，再设计主流程入口。
5. 暂缓完整聊天、WebSocket、复杂成员管理和局域网群组直传。

## 开发约定

- 文档优先使用中文。
- 根目录 README 保持简洁，只做入口和当前阶段。
- 业务文档放在 `docs/product`、`docs/api`、`docs/architecture`。
- 接手说明、当前状态、下一步计划放在 `docs/agent`。
- CI 说明放在 `docs/agent/ci.md`。
- 模块职责和边界放在 `docs/architecture/module-boundaries.md`。
- 客户端 UI 规范放在 `docs/architecture/client-ui.md`。
- 服务端按业务域组织代码，不把业务逻辑塞进 Controller。
- 客户端按 `common`、`models`、`services`、`viewmodels`、`components`、`pages` 分层。
