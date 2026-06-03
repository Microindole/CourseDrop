# 下一步任务拆解

这份文档给接手者使用，按当前产品方向列出下一轮最应该做的事情。

## 当前产品方向

CourseDrop / 课递现在定位为：

```text
本地优先的加密文件投递与分享管理工具
```

核心思路：

- 本地库管理文件，不做传统目录树。
- 公网服务器只做临时中转、扫码登录、密文消息同步和过期清理。
- 服务器不保存端到端加密密钥。
- 群组功能是 Telegram 式文件投递体验，但第一版不做完整聊天系统。

## 当前暂停点

当前先暂停功能主线，统一更新过时文档。文档完成后继续鸿蒙端群组独立测试。

## 已稳定的主线

### 临时分享文件流

```text
本地库选文件 -> 分享草稿 -> 创建公网链接 -> 上传密文/文件 -> 浏览器/App 下载 -> 过期或撤回清理
```

当前已具备：

- 服务端 `/api/shares` 主链路、浏览器 `/s/{code}` 下载页、App 下载接口。
- 扫码网页登录、`CD_SESSION` Cookie、账号密码例外登录。
- 分享撤回、续期、删除单项、审计和过期清理。
- 鸿蒙端本地库、分享草稿、上传任务、接收分享、App 下载入库。
- 客户端 AES-256-GCM 文件加密，密钥通过 URL fragment 留在客户端侧。

### Java server 群组文件流 MVP

```text
创建群 -> 加入成员 -> 发送密文消息 -> 上传密文文件 -> 成员下载密文文件
```

当前已具备：

- `group_sessions`、`group_members`、`group_messages`、`group_files`。
- `/api/groups` 创建、获取、加入、退出。
- 密文消息发送与按 cursor 同步。
- 群组密文文件上传和成员下载。
- 非成员访问拒绝。
- 群组文件过期清理和孤儿文件保护。
- 服务端测试覆盖群组消息与文件流。

## 下一轮 P0：鸿蒙群组独立测试

目标：不接入首页主流程，先在 `GroupTestPage` 验证群组 API 与加密消息。

已具备：

- `models/Group.ets`
- `services/group/GroupCryptoService.ets`
- `services/group/GroupNetworkContract.ets`
- `services/group/GroupService.ets`
- `services/group/GroupMessageService.ets`
- `viewmodels/GroupTestViewModel.ets`
- `pages/GroupTestPage.ets`

需要继续：

- 用 Java server 实机/模拟器联调 `GroupTestPage`。
- 确认注册身份、创建群、发送密文文本消息、同步并本地解密都能工作。
- 增加错误态：未配置中转源、未注册身份、server 不可达、群组不存在。

验收：

- `GroupTestPage` 可以完成一轮独立群组消息联调。
- 群名和消息 payload 在服务端数据库中不是明文。
- 页面没有接入首页 Tab 或主分享流程。

## 下一轮 P1：群组文件投递闭环

目标：在独立测试页继续补群组文件流。

建议顺序：

1. 从系统文件选择器选择文件。
2. 使用已有 `EncryptionService` 或群组文件加密封装生成密文文件和 file key。
3. 调用 `GroupNetworkContract.uploadFile` 上传密文。
4. 用 `GroupCryptoService.encryptFilePayload` 生成 `FILE` 消息。
5. 调用 `GroupMessageService.sendFileMessage`。
6. 同步消息后下载密文文件。
7. 本地解密并写入 `incoming/` 或本地库。

验收：

- 同一个群组内成员能看到 `FILE` 消息。
- 只有群组成员能下载密文文件。
- 服务端只保存密文文件和元数据。
- 客户端能用 payload 中的 file key 本地解密。

## P2：再接主流程

群组独立测试稳定后，再决定入口：

- 设置页诊断入口。
- 首页功能入口。
- 单独群组 Tab。

不要过早把群组混入当前分享草稿主流程。

## 暂缓事项

- 完整聊天体验。
- WebSocket 实时推送。
- 消息已读、撤回、编辑。
- 群主踢人、解散群、密钥轮换。
- 局域网群组直传。
- 复杂 OpenAPI 自动生成。
