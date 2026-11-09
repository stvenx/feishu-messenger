# Post Feishu Bot Messenger

This action wraps the [Feishu Bot Post Message API](https://open.feishu.cn/document/ukTMukTMukTM/ucTM5YjL3ETO24yNxkjN) which can be used to post text and markdown type notification messages.

本 Action 包装了[飞书自定义机器人发送消息的 API](https://open.feishu.cn/document/ukTMukTMukTM/ucTM5YjL3ETO24yNxkjN)，可以快速发送 text、Markdown 格式的群通知消息。

## 用法

这是一个 **composite action**，不需要 Docker。运行时取 Go 二进制执行，用 `with:` 传参。

> **v2.0.0 起不再是 Docker Action。** 迁移说明见文末「从 v1 升级」。

### 配置参数

| 参数名         | 描述                          | 必填 | 默认值 |
|--------------|----------------------------------|------|--------|
| `bot_token`    | 飞书机器人 webhook token（从 URL `https://open.feishu.cn/open-apis/bot/v2/hook/{token}` 中获取） | ✅ | - |
| `msg_type`     | 消息类型，支持 `text`、`markdown` | ❌ | `text` |
| `post_message` | 推送内容 | ❌* | - |
| `message_file` | 从文件中读取消息内容 | ❌* | - |
| `user_maps`    | 用户映射配置，格式：`stvenx:ou_xxxx,lizhi:ou_yyyy`（用户名:open_id） | ❌ | - |
| `assignees`    | 需要 @的用户列表（JSON格式），通常从 GitHub 事件中获取 | ❌ | - |
| `version`      | 二进制版本 | ❌ | `v2.0.0` |
| `release_url`  | release 下载地址前缀，可指向内网镜像 | ❌ | GitHub releases |

> \* `post_message` 和 `message_file` 二选一，至少需要提供一个。

### 基本用法

#### 发送文本消息

```yaml
- name: Notify Feishu
  uses: stvenx/feishu-messenger@v2.0.0
  with:
    bot_token: ${{ secrets.BOT_TOKEN }}
    msg_type: 'text'
    post_message: '这是一条测试消息'
```

#### 发送 Markdown 消息

```yaml
- name: Notify Feishu
  uses: stvenx/feishu-messenger@v2.0.0
  with:
    bot_token: ${{ secrets.BOT_TOKEN }}
    msg_type: 'markdown'
    post_message: |
      ### ${{ github.ref_name }} go test succeeded
      > author： <font color="warning"> ${{ github.event.head_commit.author.name }} </font>
```

> **注意**：虽然支持 `markdown` 类型，但飞书 API 实际使用 `text` 类型发送，Markdown 语法在 text 类型中同样支持。

#### 从文件读取消息

```yaml
- name: Notify Feishu from file
  uses: stvenx/feishu-messenger@v2.0.0
  with:
    bot_token: ${{ secrets.BOT_TOKEN }}
    msg_type: 'text'
    message_file: 'message.txt'
```

### @用户功能

支持在消息中 @指定用户，需要配置 `user_maps` 和 `assignees` 参数：

```yaml
- name: Notify Feishu with @users
  uses: stvenx/feishu-messenger@v2.0.0
  with:
    bot_token: ${{ secrets.BOT_TOKEN }}
    user_maps: ${{ secrets.USER_MAPS }}
    msg_type: 'text'
    post_message: |
      ### 收到新的 PR
      > 创建者：  ${{ github.event.pull_request.user.login }}
      > PR 标题： ${{ github.event.pull_request.title }}
      > PR 地址： ${{ github.event.pull_request.html_url }}
      > 项目地址： ${{ github.event.repository.html_url }}/actions
    assignees: ${{ toJson(github.event.pull_request.assignees) }}
```

**`user_maps` 格式说明**：
- 格式：`用户名:open_id,用户名:open_id`
- 示例：`stvenx:ou_xxxx,lizhi:ou_yyyy`
- 其中 `ou_xxxx` 是用户在飞书中的 open_id
- 多个映射用逗号分隔

**`assignees` 格式说明**：
- 支持 JSON 数组格式：`[{"login": "stvenx"}, {"login": "user1"}]`
- 也支持单个对象格式：`{"login": "stvenx"}`
- 通常从 GitHub 事件中获取：`${{ toJson(github.event.pull_request.assignees) }}`

**如何获取 open_id**：
1. 在飞书群聊中 @该用户
2. 查看消息源码或使用飞书开放平台 API 获取用户的 open_id
3. 或者通过飞书开放平台的「获取用户信息」接口获取

### 内网镜像

二进制默认从 GitHub releases 下载。国内网络慢或 self-hosted runner 不出网时，把产物同步到内网再指过去：

```yaml
- name: Notify Feishu
  uses: stvenx/feishu-messenger@v2.0.0
  with:
    bot_token: ${{ secrets.BOT_TOKEN }}
    post_message: 'done'
    release_url: 'https://mirror.example.com/feishu-messenger/releases/download'
```

镜像需要保持 `<release_url>/<version>/<asset>` 的目录结构，asset 名见下节。

### 向后兼容性

同时支持 `with:` 参数（推荐）和环境变量方式。使用环境变量时参数名转大写（`BOT_TOKEN`、`POST_MESSAGE` 等），但要注意环境变量必须在 job 或 workflow 级 `env:` 声明才能被 action 读到。

## 获取 BOT_TOKEN

1. 在飞书群聊中，点击右上角设置
2. 选择「群机器人」->「添加机器人」->「自定义机器人」
3. 设置机器人名称和描述
4. 完成后会生成 Webhook 地址，格式为：`https://open.feishu.cn/open-apis/bot/v2/hook/{token}`
5. 将 `{token}` 部分配置到 GitHub Secrets 中的 `BOT_TOKEN`

## 从 v1 升级

v1 是 Docker Action（`image: docker://ghcr.io/stvenx/feishu-messenger:latest`），要求 runner 上有 Docker daemon。v2 改成 composite action，不需要 Docker，可以跑在没有 daemon 的环境（比如 ARC 的 runner Pod）。

调用方只需要改 ref：

```diff
- uses: stvenx/feishu-messenger@master
+ uses: stvenx/feishu-messenger@v2.0.0
```

**入参完全不变**，`with:` 和环境变量两种写法都照旧。

ghcr.io 上的镜像不再更新，但已有 tag 仍在，钉死旧 ref 的调用方不受影响。

## 工作原理

`scripts/run.sh` 按以下顺序取二进制：

1. **action 目录缓存**（`bin/`）—— 同一 job 内重复调用不重复下载
2. **GitHub release 下载** —— 带 sha256 校验，校验失败直接退出
3. **本地 go 编译** —— 兜底。源码随 action checkout 一起到位，`go.mod` 零依赖，编译不需要网络

正常情况走第 2 步；第 3 步只在 release 不可达且 runner 上有 go 时触发。

### release 产物命名

```
feishu-messenger-<version-without-v>-<os>-<arch>[.exe]
sha256sums.txt
```

例：`feishu-messenger-2.0.0-linux-amd64`。支持 linux/darwin 的 amd64/arm64，以及 windows/amd64。

### 本地构建

```bash
VERSION=v2.0.0 ./scripts/build-release.sh   # 产物在 dist/
```

打 `v*` tag 会触发 `.github/workflows/release.yml`，自动交叉编译并建 release。

## License

基于 [MIT License](LICENSE)。


