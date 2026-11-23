# Clawd 桌宠与 Codex hooks 联动修复记录

2026 年 11 月 23 日，修复 Windows 上的 Clawd on Desk 无法接收 WSL Ubuntu 中 Codex hook 事件的问题。本次只修改本机的两个启动配置文件，使 hook 通过 Windows Node 向 Windows 桌宠投递事件。

本文记录修改前后的完整配置，方便排查和回滚，并补充 2026 年 11 月 24 日对更新后确认弹窗消失问题的排查。示例中的用户目录、安装目录均为当时本机的实际路径，其他机器需要按实际安装位置调整；文章中的示例不会被 Codex 自动加载。

## 问题原因

Codex 已开启 hooks，日志中有 `hook/started` 和 `hook/completed` 记录，但原启动脚本使用 Linux Node，访问的是 WSL 的 `127.0.0.1`。桌宠服务运行在 Windows，当前网络配置下两个环境的回环地址不互通。

实测 WSL 访问 `127.0.0.1:23333–23337` 均被拒绝；通过 Windows Node 访问 Windows 的 `127.0.0.1:23333/state` 返回 HTTP 200，响应头 `x-clawd-server` 为 `clawd-on-desk`。

桌宠的 `codex-hook.js` 在内部失败时也会以退出码 0 结束，因此仅凭进程退出码无法判断事件是否送达。验证时需要检查内部投递结果的 `posted` 字段。

## 修改文件和内容

### 启动脚本

实际文件：`/root/.codex/clawd-hooks/codex-hook.js.sh`。

完整脚本见文末。

修改前执行：

```sh
exec '/usr/local/bin/node' '/root/.claude/hooks/codex-hook.js' "$@"
```

修改后执行：

```sh
exec '/mnt/c/Program Files/nodejs/node.exe' 'D:/Tool/Clawd on Desk/resources/app.asar.unpacked/hooks/codex-hook.js' '--clawd-wsl-interop' "$@"
```

使用 Windows Node 运行 Windows 安装目录中的 hook，并增加桌宠自带的 WSL 桥接参数。保留额外参数转发，路径使用引号处理空格。脚本的 `clawd-generation` 同步更新。

### 启动记录

实际文件：`/root/.codex/clawd-hooks/codex-hook.posix.json`。

完整记录见文末。

| 字段 | 修改前 | 修改后 |
| --- | --- | --- |
| `mode` | `native` | `windows-interop` |
| `nodeBin` | `/usr/local/bin/node` | `/mnt/c/Program Files/nodejs/node.exe` |
| `target` | `/root/.claude/hooks/codex-hook.js` | `/mnt/d/Tool/Clawd on Desk/resources/app.asar.unpacked/hooks/codex-hook.js` |
| `args` | `[]` | `["--clawd-wsl-interop"]` |
| `generation` | 原启动脚本摘要 | 新启动脚本摘要 |
| `binding` | 原记录摘要 | 新记录摘要 |

`generation` 和 `binding` 配合启动内容更新，并通过桌宠自带的 `readStableCodexHookManifest` 和 `inspectStableCodexHookCommand` 校验。启动脚本中的目标使用 Windows 路径，记录中的目标使用对应的 WSL 挂载路径，便于本地文件检查。

`managedBy`、`version`、`platform` 和 `env` 保持原值。脚本权限保持 `0700`，记录权限保持 `0600`。

## 保持原样的配置

- `/root/.codex/hooks.json`：事件定义、`command`、`commandWindows` 和超时配置均未修改，已与备份进行字节比较。
- `/root/.codex/config.toml`：没有修改 hooks 开关或信任记录。
- Linux 和 Windows 安装目录中的 `codex-hook.js`：没有修改桌宠程序代码。

Codex 仍通过原有 `command` 调用稳定启动脚本，由更新后的脚本完成 Windows 桥接。

## 验证结果

通过实际启动脚本调用 `SessionStart`、`UserPromptSubmit`、`Stop`、`SessionEnd`，均以退出码 0 完成且没有标准错误输出。

进一步在 Windows Node 中调用同一 hook 模块的 `runCodexHook`，传入 `--clawd-wsl-interop` 参数，确认投递结果：

| 事件 | 状态 | `posted` | 接收端口 |
| --- | --- | --- | --- |
| `SessionStart` | `idle` | `true` | 23333 |
| `UserPromptSubmit` | `thinking` | `true` | 23333 |
| `SessionEnd` | `sleeping` | `true` | 23333 |

测试使用临时会话，并发送 `SessionEnd` 结束测试。HTTP 接口已确认接收；桌宠屏幕上的动画切换仍需通过实际对话观察。

## 更新后确认弹窗消失的排查

2026 年 11 月 24 日检查本机 Clawd on Desk 1.7.0：hook 事件可以送达，但命令权限审批和提问选项属于两条不同的处理路径，需要分别验证。

### 权限审批被交回 Codex

检查 Windows 用户数据目录中的 `clawd-prefs.json`，当时配置为：

```json
{
  "version": 21,
  "permissionBubblesEnabled": true,
  "permissionAutomationMode": "off",
  "agents": {
    "codex": {
      "enabled": true,
      "permissionsEnabled": true,
      "permissionMode": "auto"
    }
  }
}
```

以上仅摘录相关字段，不是可直接覆盖使用的完整配置。该文件及日志位于本机 Windows 的 `%APPDATA%\clawd-on-desk\`。

`permission-debug.log` 从 11 月 18 日起多次记录以下内容，时间戳为 UTC：

```text
[2026-11-18T16:26:48.088Z] /permission hit | DND=false pending=0
[2026-11-18T16:26:48.095Z] codex native permission mode -> no decision, native prompt fallback (tool=Bash)
```

这表明请求已到桌宠，且未开启免打扰；桌宠随后主动交回 Codex 原生审批，并未创建审批气泡。日志中的 `native permission mode` 是回退原因的描述，不代表配置字段当前为 `native`。

核对安装包内的 `src/prefs.js`，配置版本从 20 升到 21 时，会把旧的 `intercept` 或 `native` 一次性迁移为 `auto`。代码注释说明：旧配置无法区分用户主动选择与历史默认值，因此升级时统一迁移。当前配置已是版本 21，符合该迁移后的状态；没有升级前快照，不能仅凭当前文件确认这台机器当时的旧值。

在 `auto` 模式下，`src/codex-approval-routing.js` 会把标记为 WSL 或远程来源的请求交回 Codex；对本机请求，也要核对审批工具、权限模式和会话记录等信息后才决定是否由桌宠处理。因此，气泡开关开启并不保证每次审批都出现桌宠弹窗。

要恢复由桌宠优先接收审批，在桌宠中打开：

**设置 → AI 编程工具 → Codex → 高级 → 所有审批都交给桌宠**。

该设置对应 `agents.codex.permissionMode: "intercept"`。它决定审批由谁接收，不等于自动批准；自动处理行为仍由「权限请求处理」等设置控制。按界面说明，切换后应新开聊天，已经挂起的审批可能仍留在 Codex 中。

用户操作后再次读取配置，已确认 `permissionMode` 为 `intercept`，气泡开关为 `true`，`permissionAutomationMode` 仍为 `off`。这证明设置已保存，实际权限审批弹窗是否恢复仍需新聊天中的权限请求验证。

### 异步提问尚未被当前解析器识别

当前聊天记录中出现的是 `request_user_input_async`，参数使用 `questions[].title` 和字符串形式的 `options`。安装目录中的 `hooks/codex-user-input.js` 则只识别函数名为 `request_user_input` 的记录，问题字段使用 `question`，选项使用含 `label`、`description` 的对象。

调用已安装模块的 `parseCodexUserInputRecord`，使用相同外层记录结构进行独立测试，结果如下：

| 工具及参数格式 | 解析结果 |
| --- | --- |
| `request_user_input`，`question` 字段和对象选项 | 识别为提问请求 |
| `request_user_input_async`，`title` 字段和字符串选项 | 返回 `null`，忽略该记录 |

这确认了当前解析器对异步提问的兼容缺口。开启「所有审批都交给桌宠」不会改变提问解析逻辑，不能据此认为提问提醒也已修复。后续适配需要同时处理工具名、参数格式及实际完成或取消事件；仅修改工具名匹配不足以完成修复。

### 本次测试范围与结论

- 已核查权限请求日志、设置迁移代码、审批路由代码，并验证两种提问格式的解析结果。
- 用户启用桌宠优先审批后，已核实配置保存成功。
- 随后发送了一次异步选项提问供用户观察桌宠；截至本文记录时，尚未收到是否出现气泡的反馈。这次提问不属于权限审批，不能用于验证审批弹窗恢复。
- 本次排查没有修改桌宠安装代码、hook 定义或信任记录；异步提问兼容问题仍待适配。

后续复测应分两步：先在新聊天中观察一次真实的权限审批是否弹出桌宠气泡，再单独验证异步提问提醒，并分别记录结果。

## 备份与回滚

本机备份目录：

```text
/root/.codex/clawd-hooks/backup-wsl-interop-20261123-235720/
```

其中保存了修改前的 `codex-hook.js.sh`、`codex-hook.posix.json`，以及未修改的 `hooks.json`。

需要恢复原配置时，在本机执行以下命令。回滚后会恢复原来的 Linux Node 启动方式，也会重新出现本次确认的连接问题。

```sh
cp /root/.codex/clawd-hooks/backup-wsl-interop-20261123-235720/codex-hook.js.sh /root/.codex/clawd-hooks/codex-hook.js.sh
cp /root/.codex/clawd-hooks/backup-wsl-interop-20261123-235720/codex-hook.posix.json /root/.codex/clawd-hooks/codex-hook.posix.json
chmod 700 /root/.codex/clawd-hooks/codex-hook.js.sh
chmod 600 /root/.codex/clawd-hooks/codex-hook.posix.json
```

更改 hook 定义后，若 Codex 提示需要审核，可在 CLI 的 `/hooks` 中检查并信任当前定义。官方机制说明见 [Codex Hooks](https://learn.chatgpt.com/docs/hooks)。本次未手动改写或绕过信任记录。

## 修改前后完整配置

### 修改前的 codex-hook.js.sh

```sh
#!/bin/sh
# clawd-codex-stable-launcher-v3
# clawd-generation:94df8c819e31019d490a252ba0e0486eaa6477b97a4839afaca374c7386d7874
exec '/usr/local/bin/node' '/root/.claude/hooks/codex-hook.js' "$@"
```

### 修改前的 codex-hook.posix.json

```json
{
  "managedBy": "clawd-on-desk",
  "version": 3,
  "platform": "posix",
  "mode": "native",
  "nodeBin": "/usr/local/bin/node",
  "target": "/root/.claude/hooks/codex-hook.js",
  "args": [],
  "env": {},
  "generation": "94df8c819e31019d490a252ba0e0486eaa6477b97a4839afaca374c7386d7874",
  "binding": "0fc215db13c6be5c1691dbe02c334865f3dbc555d5557c1dd8d4606e06a44503"
}
```

### 修改后的 codex-hook.js.sh

```sh
#!/bin/sh
# clawd-codex-stable-launcher-v3
# clawd-generation:7444b19f605cb067c759cb531e3b0f4a189af30e23b3af972a2c4e8994e1f8de
exec '/mnt/c/Program Files/nodejs/node.exe' 'D:/Tool/Clawd on Desk/resources/app.asar.unpacked/hooks/codex-hook.js' '--clawd-wsl-interop' "$@"
```

### 修改后的 codex-hook.posix.json

```json
{
  "managedBy": "clawd-on-desk",
  "version": 3,
  "platform": "posix",
  "mode": "windows-interop",
  "nodeBin": "/mnt/c/Program Files/nodejs/node.exe",
  "target": "/mnt/d/Tool/Clawd on Desk/resources/app.asar.unpacked/hooks/codex-hook.js",
  "args": [
    "--clawd-wsl-interop"
  ],
  "env": {},
  "generation": "7444b19f605cb067c759cb531e3b0f4a189af30e23b3af972a2c4e8994e1f8de",
  "binding": "edc0dc5f28eefce6f0dffc0311d6b8f7607e1ea2dfdda9d06b71c1c8ba2f02b6"
}
```
