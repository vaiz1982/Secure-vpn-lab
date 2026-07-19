




ssh -p 22 root@52.201.253.5  // honepod! 






# amneziawg-docker

VPN server (AmneziaWG) + SSH honeypot (Cowrie) + monitoring (Nagios) in Docker,
with automated CI/CD and Ansible deployment.

## Why this setup

The idea is to run, on one server, at the same time:
- a working obfuscated VPN (AmneziaWG — a WireGuard fork that's harder
  to detect via DPI),
- turn the standard SSH port (22) into a bait for bots/scanners instead
  of just closing it,
- monitor that everything is alive via Nagios,
- and wrap all of this in CI/CD so the image doesn't need to be built
  by hand every time.

## Architecture




                        ┌─────────────────────────┐
        Internet ─────► │   AWS Security Group    │
                        └────────────┬────────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
         port 2222               port 22               port 51820/udp
        (real SSH)             (honeypot)              (AmneziaWG VPN)
              │                      │                      │
              ▼                      ▼                      ▼
       ┌─────────────┐      ┌────────────────┐      ┌──────────────┐
       │ systemd sshd│      │ cowrie-honeypot │      │  amneziawg   │
       │ (host, no   │      │ network:        │      │ network:     │
       │  Docker)    │      │ honeypot-net    │      │ internal     │
       └─────────────┘      └────────┬────────┘      └──────┬───────┘
                                      │                      │
                                      │   no shared network  │
                                      │   between these two  │
                                      │                      │
                             ┌────────┴──────────────────────┴────────┐
                             │              nagios                    │
                             │     networks: honeypot-net + internal  │
                             │                                        │
                             │  127.0.0.1:8080 — SSH tunnel only,     │
                             │  never exposed to the internet         │
                             └─────────────────────────────────────────┘












Key point: `honeypot-net` and `internal` are **separate** Docker networks.
The honeypot has no network path to the VPN container even if it's
compromised. Nagios is the only service with access to both networks,
since it needs to check both services.

## Components

### `vpn` (AmneziaWG)
- Built from source (`amnezia-vpn/amneziawg-go` + `amneziawg-tools`)
  in a multi-stage Dockerfile — the final image contains no compiler,
  source code, or module cache.
- `golang.org/x/crypto` and `golang.org/x/net` are bumped to `@latest`
  before building — upstream was pulling outdated versions with known CVEs.
- `cap_drop: ALL` + `cap_add: NET_ADMIN` — the only capability needed
  to bring up the TUN interface.

### `honeypot` (Cowrie)
- Listens on **22** externally (2222 internally), while the real SSH
  sits on 2222 (see the Ansible `hardening` role).
- `honeypot/etc/userdb.txt` — root/admin/ubuntu with any password.
  **Important:** empty passwords (`root:x:`) crash cowrie's parser
  (`IndexError` on `passwd[0]`) — use only the wildcard `*`.
- Decoy files must live under paths that already exist in cowrie's
  filesystem structure (`/root/`), not new directories like `/home/deploy/`.
- Limits: `cpus: 0.5`, `memory: 256M`.
- `cap_add: CHOWN, SETUID, SETGID, DAC_OVERRIDE` — the image itself does
  chown+gosu on startup.
- **Known gotcha:** the image doesn't chown `/log` itself — a fresh
  volume can trigger `PermissionError`:
  ```bash
  docker run --rm -v amneziawg-docker_honeypot-logs:/data alpine chown -R 999:999 /data


















push/PR → lint → unit-tests → build → scan → push (only on git tag)
