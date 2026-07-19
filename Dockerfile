FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Зависимости для сборки AmneziaWG (userspace + kernel module tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential pkg-config libelf-dev \
    iproute2 iptables wireguard-tools \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Клонируем и собираем amneziawg-go (userspace-реализация, не требует патча ядра)
WORKDIR /opt
RUN curl -L -o go.tar.gz https://go.dev/dl/go1.22.5.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

RUN git clone https://github.com/amnezia-vpn/amneziawg-go.git
WORKDIR /opt/amneziawg-go
RUN go build -o /usr/local/bin/amneziawg-go

WORKDIR /opt
RUN git clone https://github.com/amnezia-vpn/amneziawg-tools.git
WORKDIR /opt/amneziawg-tools/src
RUN make && make install

COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/render_config.sh /usr/local/bin/render_config.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/render_config.sh

VOLUME ["/etc/amnezia/amneziawg"]
ENTRYPOINT ["/entrypoint.sh"]
