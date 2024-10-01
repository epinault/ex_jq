FROM elixir:1.15.6-otp-25-alpine


ARG USER=default
ENV HOME /home/$USER

RUN apk --no-cache add \
    bash \
    curl \
    git \
    inotify-tools \
    make \
    ncurses \
    openssh \
    perl \
    protobuf-dev \
    sudo \
    terraform \
    tmux \
    jq \
    build-base \
    python3 \
    py3-pip \
    build-base \
    python3-dev \
    openssl-dev \
    gcompat


# Install buf
RUN PREFIX="/usr/local" && VERSION="0.52.0" && \
    curl -sSL "https://github.com/bufbuild/buf/releases/download/v${VERSION}/buf-$(uname -s)-$(uname -m).tar.gz" | \
    tar -xvzf - -C "${PREFIX}" --strip-components 1

RUN adduser -D -s /bin/bash $USER \
    && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER

RUN wget https://github.com/pre-commit/pre-commit/releases/download/v2.20.0/pre-commit-2.20.0.pyz \
    && chmod +x pre-commit-2.20.0.pyz \
    && mv pre-commit-2.20.0.pyz /usr/local/bin/pre-commit

USER $USER

# Install hex
RUN mix local.hex --force

# Install rebar
RUN mix local.rebar --force

ENV PATH="${PATH}:$HOME/.mix/escripts/"

WORKDIR /app
