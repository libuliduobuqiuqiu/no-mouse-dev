# Clawd 桌宠与 Antigravity CLI hooks 联动修复记录

2026 年 11 月 26 日，排查并修复 Windows 上的 Clawd on Desk 无法接收 WSL Ubuntu 中 Antigravity CLI hook 事件的问题。本次只修改本机的全局 hooks 配置文件 `/root/.gemini/config/hooks.json`，将事件投递切换为通过 Windows Node 调用 Windows 安装目录中的 `antigravity-hook.js`。

本文记录排查过程、修改前后的完整配置及回滚方式，方便后续复用和恢复。示例中的用户目录、安装目录均为当时本机的实际路径，其他机器需按实际安装位置调整。

## 问题原因

Antigravity CLI 启动日志（`/root/.gemini/antigravity-cli/cli.log`）显示已正常加载全局 hooks 配置：

```text
hooks_manager.go:54] loaded 1 named hooks from 1 hooks.json file(s)
```

但原 `/root/.gemini/config/hooks.json` 中 4 个事件（`PreInvocation`、`PostToolUse`、`PostInvocation`、`Stop`）均使用 WSL 内的 Linux Node 执行：

```sh
'/usr/local/bin/node' '/root/.claude/hooks/antigravity-hook.js' '<Event>'
```

由于桌宠服务运行在 Windows，当前网络配置下 WSL 与 Windows 的 `127.0.0.1` 回环地址不互通：

- 在 Linux Node 中执行 `discoverClawdPort` 返回 `null`，调用 `antigravity-hook.js` 的 `sendHookEvent` 返回 `posted: false, port: null`。
- `hooks.json` 中的 shell 包装脚本带有 fail-open 兜底逻辑，即使投递失败也会输出 `{}`（`Stop` 输出 `{"decision":"allow"}`）并以退出码 `0` 结束，因此仅从 CLI 表面无报错无法发现事件未送达。
- 通过 Windows Node 访问 Windows 的 `http://127.0.0.1:23333/state` 返回 HTTP `200`，响应头 `x-clawd-server` 为 `clawd-on-desk`，响应体为 `{"ok":true,"app":"clawd-on-desk","port":23333}`。

## 修改文件和内容

实际文件：`/root/.gemini/config/hooks.json`。

将其中的 `clawd` hook 组内 4 个事件（`PreInvocation`、`PostToolUse`、`PostInvocation`、`Stop`）的 hook 执行命令统一替换（共 4 处）：

修改前：

```sh
'/usr/local/bin/node' '/root/.claude/hooks/antigravity-hook.js' '<Event>'
```

修改后：

```sh
'/mnt/c/Program Files/nodejs/node.exe' 'D:/Tool/Clawd on Desk/resources/app.asar.unpacked/hooks/antigravity-hook.js' '<Event>'
```

说明：

- 原有的临时文件采集 stdin（`< "$in_file"`）、stdin/子进程超时 watchdog、fail-open 兜底以及末尾的本地 Linux Node JSON 校验逻辑保持不变。
- `antigravity-hook.js` 仅通过位置参数接收事件名，不需要额外的 `--clawd-wsl-interop` 参数。
- 未修改桌宠安装目录代码或 `/root/.claude/hooks/` 下的脚本文件。
- Antigravity CLI 在启动时加载 `hooks.json`，修改后建议重启 Antigravity CLI 使新配置生效。

## 验证结果

### 1. Windows Node 直接投递测试

通过 Windows Node 调用 `D:/Tool/Clawd on Desk/resources/app.asar.unpacked/hooks/antigravity-hook.js` 的 `sendHookEvent`，确认投递结果：

| 事件 | 状态 | `posted` | 接收端口 | stdout |
| --- | --- | --- | --- | --- |
| `PreInvocation` | `thinking` | `true` | `23333` | `{}` |
| `PostInvocation` | `idle` | `true` | `23333` | `{}` |

### 2. 实际 `hooks.json` 命令端到端测试

按修改后的 `/root/.gemini/config/hooks.json` 中各事件的完整 shell 命令，使用临时测试会话传入 JSON payload 依次执行：

| 事件 | 退出码 | 耗时 | stdout | stderr |
| --- | --- | --- | --- | --- |
| `PreInvocation` | `0` | 479 ms | `{}` | 空 |
| `PostToolUse` | `0` | 408 ms | `{}` | 空 |
| `Stop` | `0` | 409 ms | `{"decision":"allow"}` | 空 |
| `PostInvocation` | `0` | 423 ms | `{}` | 空 |

测试末尾发送了 `PostInvocation` 将临时会话置为 `idle`。HTTP 投递与命令耗时均正常（均在 500 ms 内，远低于 6 秒 watchdog 与 10 秒超时限制）。

## 备份与回滚

本机备份文件：

```text
/root/.gemini/config/hooks.json.bak-wsl-interop-20261126
```

如需恢复修改前的配置，在本机执行：

```sh
cp /root/.gemini/config/hooks.json.bak-wsl-interop-20261126 /root/.gemini/config/hooks.json
```

回滚后会恢复 Linux Node 调用方式，也会重新出现 WSL 无法连接 Windows 桌宠的问题。

## 修改后的完整配置

实际生效文件：`/root/.gemini/config/hooks.json`

```json
{
  "clawd": {
    "PreInvocation": [
      {
        "type": "command",
        "command": "tmp_dir=${TMPDIR:-/tmp}; in_file=$(mktemp \"$tmp_dir/clawd-agy-in.XXXXXX\" 2>/dev/null || printf '%s/clawd-agy-in-%s' \"$tmp_dir\" \"$$\"); out_file=$(mktemp \"$tmp_dir/clawd-agy-out.XXXXXX\" 2>/dev/null || printf '%s/clawd-agy-out-%s' \"$tmp_dir\" \"$$\"); pid=; watchdog=; cleanup(){ trap - EXIT HUP INT TERM; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$pid\" ] && kill \"$pid\" 2>/dev/null; rm -f \"$in_file\" \"$out_file\"; }; trap cleanup EXIT HUP INT; { cat <&3 > \"$in_file\" 2>/dev/null & pid=$!; } 3<&0; ( sleep 2; kill \"$pid\" 2>/dev/null ) > /dev/null 2>&1 & watchdog=$!; wait \"$pid\" 2>/dev/null; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$watchdog\" ] && wait \"$watchdog\" 2>/dev/null; pid=; watchdog=; '/mnt/c/Program Files/nodejs/node.exe' 'D:/Tool/Clawd on Desk/resources/app.asar.unpacked/hooks/antigravity-hook.js' 'PreInvocation' < \"$in_file\" > \"$out_file\" 2>/dev/null & pid=$!; ( sleep 6; kill \"$pid\" 2>/dev/null ) > /dev/null 2>&1 & watchdog=$!; wait \"$pid\" 2>/dev/null; status=$?; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$watchdog\" ] && wait \"$watchdog\" 2>/dev/null; pid=; watchdog=; out=$(cat \"$out_file\" 2>/dev/null); if [ \"$status\" -eq 0 ] && [ -n \"$out\" ] && printf '%s' \"$out\" | '/usr/local/bin/node' '-e' 'let s='\\'''\\'';process.stdin.setEncoding('\\''utf8'\\'');process.stdin.on('\\''data'\\'',c=>s+=c);process.stdin.on('\\''end'\\'',()=>{try{const v=JSON.parse(s);if(!v||typeof v!=='\\''object'\\''||Array.isArray(v))process.exit(1);}catch{process.exit(1);}});' 2>/dev/null; then printf '%s\\n' \"$out\"; else printf '%s\\n' '{}'; fi; exit 0",
        "timeout": 10
      }
    ],
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "tmp_dir=${TMPDIR:-/tmp}; in_file=$(mktemp \"$tmp_dir/clawd-agy-in.XXXXXX\" 2>/dev/null || printf '%s/clawd-agy-in-%s' \"$tmp_dir\" \"$$\"); out_file=$(mktemp \"$tmp_dir/clawd-agy-out.XXXXXX\" 2>/dev/null || printf '%s/clawd-agy-out-%s' \"$tmp_dir\" \"$$\"); pid=; watchdog=; cleanup(){ trap - EXIT HUP INT TERM; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$pid\" ] && kill \"$pid\" 2>/dev/null; rm -f \"$in_file\" \"$out_file\"; }; trap cleanup EXIT HUP INT; { cat <&3 > \"$in_file\" 2>/dev/null & pid=$!; } 3<&0; ( sleep 2; kill \"$pid\" 2>/dev/null ) > /dev/null 2>&1 & watchdog=$!; wait \"$pid\" 2>/dev/null; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$watchdog\" ] && wait \"$watchdog\" 2>/dev/null; pid=; watchdog=; '/mnt/c/Program Files/nodejs/node.exe' 'D:/Tool/Clawd on Desk/resources/app.asar.unpacked/hooks/antigravity-hook.js' 'PostToolUse' < \"$in_file\" > \"$out_file\" 2>/dev/null & pid=$!; ( sleep 6; kill \"$pid\" 2>/dev/null ) > /dev/null 2>&1 & watchdog=$!; wait \"$pid\" 2>/dev/null; status=$?; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$watchdog\" ] && wait \"$watchdog\" 2>/dev/null; pid=; watchdog=; out=$(cat \"$out_file\" 2>/dev/null); if [ \"$status\" -eq 0 ] && [ -n \"$out\" ] && printf '%s' \"$out\" | '/usr/local/bin/node' '-e' 'let s='\\'''\\'';process.stdin.setEncoding('\\''utf8'\\'');process.stdin.on('\\''data'\\'',c=>s+=c);process.stdin.on('\\''end'\\'',()=>{try{const v=JSON.parse(s);if(!v||typeof v!=='\\''object'\\''||Array.isArray(v))process.exit(1);}catch{process.exit(1);}});' 2>/dev/null; then printf '%s\\n' \"$out\"; else printf '%s\\n' '{}'; fi; exit 0",
            "timeout": 10
          }
        ]
      }
    ],
    "PostInvocation": [
      {
        "type": "command",
        "command": "tmp_dir=${TMPDIR:-/tmp}; in_file=$(mktemp \"$tmp_dir/clawd-agy-in.XXXXXX\" 2>/dev/null || printf '%s/clawd-agy-in-%s' \"$tmp_dir\" \"$$\"); out_file=$(mktemp \"$tmp_dir/clawd-agy-out.XXXXXX\" 2>/dev/null || printf '%s/clawd-agy-out-%s' \"$tmp_dir\" \"$$\"); pid=; watchdog=; cleanup(){ trap - EXIT HUP INT TERM; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$pid\" ] && kill \"$pid\" 2>/dev/null; rm -f \"$in_file\" \"$out_file\"; }; trap cleanup EXIT HUP INT; { cat <&3 > \"$in_file\" 2>/dev/null & pid=$!; } 3<&0; ( sleep 2; kill \"$pid\" 2>/dev/null ) > /dev/null 2>&1 & watchdog=$!; wait \"$pid\" 2>/dev/null; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$watchdog\" ] && wait \"$watchdog\" 2>/dev/null; pid=; watchdog=; '/mnt/c/Program Files/nodejs/node.exe' 'D:/Tool/Clawd on Desk/resources/app.asar.unpacked/hooks/antigravity-hook.js' 'PostInvocation' < \"$in_file\" > \"$out_file\" 2>/dev/null & pid=$!; ( sleep 6; kill \"$pid\" 2>/dev/null ) > /dev/null 2>&1 & watchdog=$!; wait \"$pid\" 2>/dev/null; status=$?; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$watchdog\" ] && wait \"$watchdog\" 2>/dev/null; pid=; watchdog=; out=$(cat \"$out_file\" 2>/dev/null); if [ \"$status\" -eq 0 ] && [ -n \"$out\" ] && printf '%s' \"$out\" | '/usr/local/bin/node' '-e' 'let s='\\'''\\'';process.stdin.setEncoding('\\''utf8'\\'');process.stdin.on('\\''data'\\'',c=>s+=c);process.stdin.on('\\''end'\\'',()=>{try{const v=JSON.parse(s);if(!v||typeof v!=='\\''object'\\''||Array.isArray(v))process.exit(1);}catch{process.exit(1);}});' 2>/dev/null; then printf '%s\\n' \"$out\"; else printf '%s\\n' '{}'; fi; exit 0",
        "timeout": 10
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": "tmp_dir=${TMPDIR:-/tmp}; in_file=$(mktemp \"$tmp_dir/clawd-agy-in.XXXXXX\" 2>/dev/null || printf '%s/clawd-agy-in-%s' \"$tmp_dir\" \"$$\"); out_file=$(mktemp \"$tmp_dir/clawd-agy-out.XXXXXX\" 2>/dev/null || printf '%s/clawd-agy-out-%s' \"$tmp_dir\" \"$$\"); pid=; watchdog=; cleanup(){ trap - EXIT HUP INT TERM; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$pid\" ] && kill \"$pid\" 2>/dev/null; rm -f \"$in_file\" \"$out_file\"; }; trap cleanup EXIT HUP INT; { cat <&3 > \"$in_file\" 2>/dev/null & pid=$!; } 3<&0; ( sleep 2; kill \"$pid\" 2>/dev/null ) > /dev/null 2>&1 & watchdog=$!; wait \"$pid\" 2>/dev/null; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$watchdog\" ] && wait \"$watchdog\" 2>/dev/null; pid=; watchdog=; '/mnt/c/Program Files/nodejs/node.exe' 'D:/Tool/Clawd on Desk/resources/app.asar.unpacked/hooks/antigravity-hook.js' 'Stop' < \"$in_file\" > \"$out_file\" 2>/dev/null & pid=$!; ( sleep 6; kill \"$pid\" 2>/dev/null ) > /dev/null 2>&1 & watchdog=$!; wait \"$pid\" 2>/dev/null; status=$?; [ -n \"$watchdog\" ] && kill \"$watchdog\" 2>/dev/null; [ -n \"$watchdog\" ] && wait \"$watchdog\" 2>/dev/null; pid=; watchdog=; out=$(cat \"$out_file\" 2>/dev/null); if [ \"$status\" -eq 0 ] && [ -n \"$out\" ] && printf '%s' \"$out\" | '/usr/local/bin/node' '-e' 'let s='\\'''\\'';process.stdin.setEncoding('\\''utf8'\\'');process.stdin.on('\\''data'\\'',c=>s+=c);process.stdin.on('\\''end'\\'',()=>{try{const v=JSON.parse(s);if(!v||typeof v!=='\\''object'\\''||Array.isArray(v))process.exit(1);}catch{process.exit(1);}});' 2>/dev/null; then printf '%s\\n' \"$out\"; else printf '%s\\n' '{\"decision\":\"allow\"}'; fi; exit 0",
        "timeout": 10
      }
    ]
  }
}
```
