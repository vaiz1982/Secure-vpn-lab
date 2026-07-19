# syntax=docker/dockerfile:1

# ---- Stage 1: builder ----
# Здесь собираем amneziawg-go и amneziawg-tools. Весь этот слой
# (компилятор Go, исходники, кэш модулей) НЕ попадает в финальный
# образ — именно там Trivy находил CVE в самом Go-тулчейне.
FROM golang:1.25-bookworm AS builder

# Не даём Go тихо скачать другую (возможно устаревшую/уязвимую)
# версию тулчейна поверх той, что уже в базовом образе.
ENV GOTOOLCHAIN=local
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential pkg-config libelf-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN mkdir -p /out && git clone https://github.com/amnezia-vpn/amneziawg-go.git
WORKDIR /opt/amneziawg-go
RUN go build -o /out/amneziawg-go

WORKDIR /opt
RUN git clone https://github.com/amnezia-vpn/amneziawg-tools.git
WORKDIR /opt/amneziawg-tools/src
RUN make && make DESTDIR=/out/tools install

# ---- Stage 2: runtime ----
# Минимальный слой — только то, что реально нужно контейнеру в работе.
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    iproute2 iptables wireguard-tools \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/amneziawg-go /usr/local/bin/amneziawg-go
COPY --from=builder /out/tools/usr/bin/ /usr/local/bin/

COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/render_config.sh /usr/local/bin/render_config.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/render_config.sh /usr/local/bin/amneziawg-go

VOLUME ["/etc/amnezia/amneziawg"]
ENTRYPOINT ["/entrypoint.sh"]
