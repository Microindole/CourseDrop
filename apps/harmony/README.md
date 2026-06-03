# 鸿蒙客户端

CourseDrop 的原生鸿蒙客户端，使用 ArkTS / ArkUI，Stage 模型。

## 目录结构

```text
AppScope/          应用级元数据和资源
entry/             Entry HAP 模块
  src/main/ets/
    common/        配置、主题、Preferences、RDB 和运行时上下文
    components/    通用组件和 CourseDrop 业务组件
    entryability/  UIAbility 入口
    models/        分享、传输、本地库、设备、身份、群组等模型
    pages/         首页、分享、本地库、设备、设置、接收分享和独立测试页
    services/      REST、文件、加密、身份、分享、传输、扫码、局域网、群组等服务
    viewmodels/    页面状态与业务编排
```

## 当前状态

客户端已经进入真实链路联调和群组独立测试阶段：

- `HomePage` 是主入口，内部使用底部 Tab 承载首页、分享、本地库、设备和设置。
- 本地库支持应用目录、RDB 索引、导入/生成测试文件、搜索、分页、详情、批量加入分享草稿。
- 分享页围绕 CourseDrop 分享草稿、公网链接、二维码、上传任务、撤回、续期和失败重试组织。
- 接收分享页支持输入分享码、读取服务端文件列表、App 身份鉴权下载、写入 `incoming/` 并入库。
- E2EE 已使用 `cryptoFramework` 的 AES-256-GCM，上传前加密，密钥通过分享 URL fragment 保留在客户端侧。
- 设置页支持中转源、健康探测、本机身份注册、账号创建和账号密码登录开关。
- 扫码服务已有边界；当前系统相机只能返回拍摄 URI，真实二维码解码后续接 Scan Kit 或图像解码库。
- 局域网发现已从假扫描改成 UDP 广播发现服务边界，但直传协议尚未完成。
- 群组模块已新增模型、AES-GCM 群组加密、HTTP contract 和 `GroupTestPage` 独立测试页；暂未接入首页主流程。

## 独立测试页

`entry/src/main/ets/pages/GroupTestPage.ets` 已注册到 `main_pages.json`，用于手动验证群组服务端：

```text
设置中转源 -> 注册本机身份 -> 创建测试群 -> 发送密文文本消息 -> 同步并本地解密显示
```

该页面没有入口按钮，暂不进入首页或 Tab 主流程。

## 运行与验证

鸿蒙完整构建依赖 DevEco Studio / Hvigor 环境。当前仓库侧可先通过源码结构检查和服务端测试配合联调。

## 下一步

- 在独立测试页继续补群组文件选择、加密上传、`FILE` 消息生成、下载和本地解密。
- 群组链路稳定后，再决定入口放到设置诊断区还是主 Tab。
- 继续补真实二维码解码、账号设备管理和局域网直传。
