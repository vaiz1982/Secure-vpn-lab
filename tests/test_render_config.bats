#!/usr/bin/env bats
setup() {
    load_render() { source "${BATS_TEST_DIRNAME}/../scripts/render_config.sh"; }
    load_render
}

@test "генерирует базовый [Interface] блок с приватным ключом" {
    SERVER_PRIV="testkey123=" run render_config
    [ "$status" -eq 0 ]
    [[ "$output" == *"PrivateKey = testkey123="* ]]
}

@test "использует дефолтный порт 51820 если WG_PORT не задан" {
    SERVER_PRIV="k" run render_config
    [[ "$output" == *"ListenPort = 51820"* ]]
}

@test "уважает кастомный WG_PORT" {
    SERVER_PRIV="k" WG_PORT=12345 run render_config
    [[ "$output" == *"ListenPort = 12345"* ]]
}

@test "падает без SERVER_PRIV" {
    unset SERVER_PRIV
    run render_config
    [ "$status" -ne 0 ]
}

@test "падает на некорректном порту (>65535)" {
    SERVER_PRIV="k" WG_PORT=99999 run render_config
    [ "$status" -ne 0 ]
    [[ "$output" == *"invalid WG_PORT"* ]]
}

@test "падает на нечисловом порту" {
    SERVER_PRIV="k" WG_PORT="abc" run render_config
    [ "$status" -ne 0 ]
}

@test "падает если Jmin > Jmax" {
    SERVER_PRIV="k" WG_JMIN=100 WG_JMAX=10 run render_config
    [ "$status" -ne 0 ]
    [[ "$output" == *"WG_JMIN"* ]]
}

@test "содержит PostUp/PostDown правила iptables для NAT" {
    SERVER_PRIV="k" run render_config
    [[ "$output" == *"MASQUERADE"* ]]
    [[ "$output" == *"PostUp"* ]]
    [[ "$output" == *"PostDown"* ]]
}
