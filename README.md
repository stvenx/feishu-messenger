# Post Feishu Bot Messenger

This action wraps the [Feishu Bot Post Message API](https://open.feishu.cn/document/ukTMukTMukTM/ucTM5YjL3ETO24yNxkjN) which can be used to post text and markdown type notification messages.

本 Action 包装了[飞书自定义机器人发送消息的 API](https://open.feishu.cn/document/ukTMukTMukTM/ucTM5YjL3ETO24yNxkjN)，可以快速发送 text、Markdown 格式的群通知消息。

## 用法

这是一个 Docker Action，使用 `with:` 参数传递配置。将发送消息的 token 参数配置到 GitHub Secret 中，并配置发送的消息内容。

### 配置参数

| 参数名         | 描述                          | 必填 | 默认值 |
|--------------|----------------------------------|------|--------|
| `bot_token`    | 飞书机器人 webhook token（从 URL `https://open.feishu.cn/open-apis/bot/v2/hook/{token}` 中获取） | ✅ | - |
| `msg_type`     | 消息类型，支持 `text`、`markdown` | ❌ | `text` |
| `post_message` | 推送内容 | ❌* | - |
| `message_file` | 从文件中读取消息内容 | ❌* | - |
| `user_maps`    | 用户映射配置，格式：`stvenx:ou_xxxx,lizhi:ou_yyyy`（用户名:open_id） | ❌ | - |
| `assignees`    | 需要 @的用户列表（JSON格式），通常从 GitHub 事件中获取 | ❌ | - |

> \* `post_message` 和 `message_file` 二选一，至少需要提供一个。

### 基本用法

#### 发送文本消息

```yaml
- name: Notify Feishu
  uses: stvenx/feishu-messenger@v1
  with:
    bot_token: ${{ secrets.BOT_TOKEN }}
    msg_type: 'text'
    post_message: '这是一条测试消息'
```

#### 发送 Markdown 消息

```yaml
- name: Notify Feishu
  uses: stvenx/feishu-messenger@v1
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
  uses: stvenx/feishu-messenger@v1
  with:
    bot_token: ${{ secrets.BOT_TOKEN }}
    msg_type: 'text'
    message_file: 'message.txt'
```

### @用户功能

支持在消息中 @指定用户，需要配置 `user_maps` 和 `assignees` 参数：

```yaml
- name: Notify Feishu with @users
  uses: stvenx/feishu-messenger@v1
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

### 向后兼容性

本 Action 同时支持 `with:` 参数（推荐）和环境变量方式。如果使用环境变量，参数名需要转换为大写格式（如 `BOT_TOKEN`、`POST_MESSAGE` 等）。

## 获取 BOT_TOKEN

1. 在飞书群聊中，点击右上角设置
2. 选择「群机器人」->「添加机器人」->「自定义机器人」
3. 设置机器人名称和描述
4. 完成后会生成 Webhook 地址，格式为：`https://open.feishu.cn/open-apis/bot/v2/hook/{token}`
5. 将 `{token}` 部分配置到 GitHub Secrets 中的 `BOT_TOKEN`

## License

基于 [MIT License](LICENSE)。

