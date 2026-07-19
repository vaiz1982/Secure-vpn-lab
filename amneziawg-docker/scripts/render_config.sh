#!/bin/bash
render_config() {
    local priv="${SERVER_PRIV:?SERVER_PRIV is required}"
    local port="${WG_PORT:-51820}"
    local address="${WG_ADDRESS:-10.13.13.1/24}"
    local jc="${WG_JC:-4}"
    local jmin="${WG_JMIN:-40}"
    local jmax="${WG_JMAX:-70}"
    local s1="${WG_S1:-0}"
    local s2="${WG_S2:-0}"

    if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
        echo "ERROR: invalid WG_PORT='$port'" >&2
        return 1
    fi
    if (( jmin > jmax )); then
        echo "ERROR: WG_JMIN ($jmin) > WG_JMAX ($jmax)" >&2
        return 1
    fi

    cat <<EOF
[Interface]
PrivateKey = ${priv}
Address = ${address}
ListenPort = ${port}
Jc = ${jc}
Jmin = ${jmin}
Jmax = ${jmax}
S1 = ${s1}
S2 = ${s2}

PostUp = iptables -A FORWARD -i awg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i awg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    render_config
fi
