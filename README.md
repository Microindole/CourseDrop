# CourseDrop / 课递

本地优先的加密文件投递与分享管理工具。

CourseDrop 不做普通网盘，也不做完整聊天系统。当前主线是先稳定“本地库 -> 加密分享 -> 公网限时中转 -> 浏览器/App 下载 -> 过期清理”，再扩展到“加密群组文件流”。

## 目录

- [产品说明](docs/product/overview.md)
- [开发路线](docs/product/roadmap.md)
- [系统设计](docs/architecture/system-design.md)
- [数据模型](docs/architecture/data-model.md)
- [模块边界](docs/architecture/module-boundaries.md)
- [客户端 UI 规范](docs/architecture/client-ui.md)
- [REST API](docs/api/rest-api.md)
- [WebSocket 事件草案](docs/api/websocket-events.md)
- [Agent 接手指南](docs/agent/handbook.md)
- [下一步任务拆解](docs/agent/next-steps.md)
- [当前状态](docs/agent/status.md)
- [CI 说明](docs/agent/ci.md)
- [鸿蒙客户端](apps/harmony/README.md)
- [Java 服务端](apps/server/README.md)

## 当前阶段

公网分享闭环、端到端加密基础、扫码登录、App 下载入库和 Java 服务端群组文件流 MVP 已具备。当前暂停功能主线，先校准文档；下一步再继续做鸿蒙端群组独立测试到完整文件投递。

```text
临时分享：本地库 -> 分享草稿 -> 创建链接 -> 上传密文 -> 浏览器/App 下载
群组文件流：创建群 -> 加入成员 -> 上传密文文件 -> 同步密文消息 -> 下载解密
```
