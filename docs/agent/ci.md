# CI 说明

项目使用 GitHub Actions 做持续集成，配置位于 `.github`。

## 设计原则

- workflow 只负责编排。
- 具体检查封装成 `.github/actions` 下的 composite action 或 `scripts/ci` 脚本。
- CI 先识别改动区域，再只运行相关检查，避免文档改动强制跑完整服务端。
- 服务端编译和测试拆开，定位失败更直接。
- 文档检查不只看文件是否存在，还会检查本地链接和关键状态描述。
- 外部 Markdown 链接检查作为 advisory，避免网络波动阻塞主线。
- 鸿蒙端在通用 CI 中做结构、路由和 service barrel 检查；完整 HAP 构建仍放在 release workflow。

## Workflows

```text
.github/workflows/ci.yml
.github/workflows/deploy-server.yml
.github/workflows/release-harmony.yml
```

## `ci.yml`

`ci.yml` 包含以下 job：

- `changes`：使用路径过滤识别本次改动涉及 `ci`、`docs`、`server`、`harmony` 哪些区域。
- `format`：检查仓库元文件和 CI 脚本的基础文本格式。
- `docs-required`：检查关键文档、README 入口、本地 Markdown 链接和当前状态关键描述。
- `docs-external-links`：检查外部 Markdown 链接，允许失败。
- `server-compile`：Java server 不跑测试的编译检查。
- `server-tests`：Java server 单元/集成测试，并上传 Surefire 报告。
- `harmony-structure`：检查鸿蒙工程结构、路由页面和 service barrel。
- `ci-summary`：汇总本次改动区域和各 job 结果。

路径过滤规则：

```text
docs    -> README.md、docs/**、apps/*/README.md、文档检查脚本
server  -> apps/server/**、deploy/**
harmony -> apps/harmony/**、鸿蒙检查脚本
ci      -> .github/**、scripts/ci/**
```

## Composite Actions

```text
.github/actions/check-docs
.github/actions/check-format
.github/actions/build-server
.github/actions/check-harmony
.github/actions/build-harmony
```

### `check-docs`

检查：

- 关键文档入口存在且非空。
- 根 README 指向重要入口。
- 本地 Markdown 链接有效。
- 文档中包含当前主线关键描述，例如群组文件流、`GroupTestPage`、`/api/groups`。
- 旧阶段描述没有回流，例如早期首页占位、早期模型优先等说法。

### `check-format`

当前只检查仓库元文件和 CI 脚本，避免历史源码 CRLF/尾随空格问题阻塞功能 CI。

后续如果要扩大范围，建议先单独做一次格式归一化提交，再把 `apps` 和 `docs` 加入格式检查。

### `build-server`

负责设置 Java 17 和 Maven cache，并运行可配置的 Maven phase：

```text
maven-goal: -DskipTests compile
maven-goal: test
maven-goal: verify
```

### `check-harmony`

检查：

- HarmonyOS 标准工程文件。
- `common/components/models/pages/services/viewmodels` 等分层目录。
- `main_pages.json` 引用的页面文件是否存在。
- 路由页面是否包含 `@Entry`。
- 关键 service 子域是否都有 `index.ets`。
- `GroupTestPage` 暂时没有接入 `HomePage` 主流程。

### `build-harmony`

用于 release workflow。它会下载 Harmony 命令行工具和 SDK，执行 HAP 构建。

## 部署与发布

`deploy-server.yml` 是服务器发布工作流：

- `main` 分支更新且命中 server/deploy 相关路径时自动运行。
- `workflow_dispatch` 可手动运行。
- 构建并测试 Java server。
- 上传 jar 到 `/home/cd/coursedrop/incoming`。
- 通过 `systemctl --user restart coursedrop` 重启 `cd` 用户服务。

部署说明见 `docs/deploy/server-debian.md`。

`release-harmony.yml` 是鸿蒙 ArkTS 客户端发布工作流：

- `main` 分支命中 `apps/harmony/**` 或相关 CI 文件时自动构建 `dev` 版本。
- tag 推送会按 tag 名创建对应版本 release。
- 默认从本仓库 `harmony-toolchain` release 下载 `harmony-command-line-tools-linux.zip`。
- 如需覆盖下载源，可配置仓库 secret `HARMONY_COMMANDLINE_TOOLS_URL`。

## 后续增强

- 把服务端测试继续拆成 fast/unit 和 flow/integration。
- 给群组 API 增加专门的契约测试 job。
- 在完成一次格式归一化后，把 docs 和 apps 纳入严格格式检查。
- 如果 Harmony CLI 环境稳定，可把 HAP smoke build 加入 PR 可选 job。
