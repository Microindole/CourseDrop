#!/usr/bin/env python3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

REQUIRED_SNIPPETS = {
    "README.md": [
        "临时分享",
        "群组文件流",
    ],
    "apps/harmony/README.md": [
        "GroupTestPage",
        "群组独立测试",
    ],
    "apps/server/README.md": [
        "/api/groups",
        "群组文件流 MVP",
    ],
    "docs/agent/next-steps.md": [
        "鸿蒙群组独立测试",
        "群组文件投递闭环",
    ],
    "docs/agent/status.md": [
        "群组文件流 MVP",
        "GroupTestPage",
    ],
    "docs/architecture/data-model.md": [
        "GroupSession",
        "ServerGroupFile",
    ],
}

STALE_SNIPPETS = {
    "首页壳",
    "模型层 -> mock",
    "不做私聊和群聊",
    "当前先稳定鸿蒙客户端的信息架构",
    "CleanupTask",
    "WebSocket：房间",
    "房间、上传、下载、剪贴板",
}

STALE_SKIP_FILES = {
    "docs/architecture/group-feature-plan.md",
}


def main() -> int:
    errors: list[str] = []

    for rel, snippets in REQUIRED_SNIPPETS.items():
        path = ROOT / rel
        text = path.read_text(encoding="utf-8")
        for snippet in snippets:
            if snippet not in text:
                errors.append(f"{rel}: missing current-state snippet: {snippet}")

    for path in tracked_markdown_files():
        rel = path.relative_to(ROOT).as_posix()
        if rel in STALE_SKIP_FILES:
            continue
        text = path.read_text(encoding="utf-8")
        for snippet in STALE_SNIPPETS:
            if snippet in text:
                errors.append(f"{rel}: stale wording remains: {snippet}")

    if errors:
        print("Documentation content check failed:")
        for error in errors:
            print(f"  {error}")
        return 1
    print("Documentation content check passed.")
    return 0


def tracked_markdown_files() -> list[Path]:
    import subprocess

    result = subprocess.run(
        ["git", "ls-files", "-z", "*.md"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    )
    return [ROOT / item.decode("utf-8") for item in result.stdout.split(b"\0") if item]


if __name__ == "__main__":
    raise SystemExit(main())
