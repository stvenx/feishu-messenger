FROM alpine:latest


LABEL "com.github.actions.name"="Feishu Messenger"
LABEL "com.github.actions.description"="Post Feishu messages from your own bot"
LABEL "com.github.actions.icon"="bell"
LABEL "com.github.actions.color"="blue"

LABEL version="1.0.0"
LABEL repository="https://github.com/stvenx/feishu-messager.git"
LABEL homepage="https://github.com/stvenx/feishu-messager.git"
LABEL maintainer="stvenx"

RUN apk --no-cache add curl sed bash jq

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

