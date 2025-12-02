# Post Feishu Bot Messenger

This action wraps the [Feishu Bot Post Message API](https://open.feishu.cn/document/ukTMukTMukTM/ucTM5YjL3ETO24yNxkjN) which can be used to post text and markdown type notification messages.

本 Action 包装了[飞书自定义机器人发送消息的 API](https://open.feishu.cn/document/ukTMukTMukTM/ucTM5YjL3ETO24yNxkjN)，可以快速发送 text、Markdown 格式的群通知消息。

## 用法

将发送消息的 token 参数配置到 GitHub Secret 中，并配置发送的消息内容。

配置参数：

| 参数名         | 描述                          |
|--------------|----------------------------------|
| BOT_TOKEN    | 飞书机器人 webhook token（从 URL `https://open.feishu.cn/open-apis/bot/v2/hook/{token}` 中获取） |
| MSG_TYPE     | 支持 text、markdown              |
| POST_MESSAGE | 推送内容                 |
| MESSAGE_FILE | 从MESSAGE_FILE中读取消息内容    |
| USER_MAPS    | 用户映射配置，格式：`stvenx:ou_xxxx,lizhi:ou_yyyy`（用户名:open_id） |
| ASSIGNEES    | 需要 @的用户列表（JSON格式），通常从 GitHub 事件中获取 |


POST_MESSAGE和MESSAGE_FILE二选一

```yaml
- name: Notify Feishu
  uses: stvenx/feishu-messager@v1
  env:
    BOT_TOKEN: ${{ secrets.BOT_TOKEN }}
    MSG_TYPE: 'text'
    POST_MESSAGE: '这是一条测试消息'
```

```yaml
- name: Notify Feishu
  uses: stvenx/feishu-messager@v1
  env:
    BOT_TOKEN: ${{ secrets.BOT_TOKEN }}
    MSG_TYPE: 'markdown'
    POST_MESSAGE: |
      ### ${{ github.ref_name }} go test succeeded
      > author： <font color="warning"> ${{ github.event.head_commit.author.name }} </font>
```

```yaml
- name: Notify Feishu from file
  uses: stvenx/feishu-messager@v1
  env:
    BOT_TOKEN: ${{ secrets.BOT_TOKEN }}
    MSG_TYPE: 'text'
    MESSAGE_FILE: 'message.txt'
```

### @用户功能

支持在消息中 @指定用户，需要配置 `USER_MAPS` 和 `ASSIGNEES` 环境变量：

```yaml
- name: Notify Feishu with @users
  uses: stvenx/feishu-messager@v1
  env:
    BOT_TOKEN: ${{ secrets.BOT_TOKEN }}
    USER_MAPS: ${{ secrets.USER_MAPS }}
    MSG_TYPE: text
    POST_MESSAGE: |
      ### 收到新的 PR
      > 创建者：  ${{ github.event.pull_request.user.login }}
      > PR 标题： ${{ github.event.pull_request.title }}
      > PR 地址： ${{ github.event.pull_request.html_url }}
      > 项目地址： ${{ github.event.repository.html_url }}/actions
    ASSIGNEES: ${{ toJson(github.event.pull_request.assignees) }}
```

**USER_MAPS 格式说明**：
- 格式：`用户名:open_id,用户名:open_id`
- 示例：`stvenx:ou_xxxx,lizhi:ou_yyyy`
- 其中 `ou_xxxx` 是用户在飞书中的 open_id

**如何获取 open_id**：
1. 在飞书群聊中 @该用户
2. 查看消息源码或使用飞书开放平台 API 获取用户的 open_id
3. 或者通过飞书开放平台的「获取用户信息」接口获取

## 获取 BOT_TOKEN

1. 在飞书群聊中，点击右上角设置
2. 选择「群机器人」->「添加机器人」->「自定义机器人」
3. 设置机器人名称和描述
4. 完成后会生成 Webhook 地址，格式为：`https://open.feishu.cn/open-apis/bot/v2/hook/{token}`
5. 将 `{token}` 部分配置到 GitHub Secrets 中的 `BOT_TOKEN`

## License

基于 [MIT License](LICENSE)。

