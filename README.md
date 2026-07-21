Trivy always FIRST!!!!!!!!!!!


we need dockerhub secrets add to Git!!!!!both!!!!!!!
we use Blink terminal for it! !!!!!!!!!!!


port 2222 // real ssh , avalable only from bastion host!!!!!!!!!!!!!

ssh -p 22 root@52.201.253.5  // honepod!,monitoring !!!!!!!!!!!!!!!

ssh -i some1 -p 2222 -L 8080:127.0.0.1:8080 ubuntu@52.201.253.5 // nagious
http://localhost:8080 //only local forwarding ! !!!!!!!!!!!!


sudo docker exec amneziawg awg show  // check if vpn work! 
nc -zvu 52.201.253.5 51820  //confirm richable from outside not inside!!!!!!!











What you built:

1. A VPN server (AmneziaWG) — obfuscated WireGuard fork, running in Docker, 
   built from source with a hardened multi-stage image (no compiler/CVEs 
   left in the final image)

2. An SSH honeypot (Cowrie) — sitting on port 22 to catch and log 
   scanners/bots, with realistic decoy files (fake passwd, bash history, 
   "leaked" credentials) so it looks like a real compromised server

3. Monitoring (Nagios) — checks that VPN, SSH, and honeypot are all alive, 
   accessible only through an SSH tunnel

4. Hardened SSH — moved to port 2222, root/password login disabled, 
   fail2ban active

5. Network isolation — honeypot and VPN sit in separate Docker networks, 
   so even if the honeypot got compromised it has no path to the VPN

6. Full CI/CD — GitHub Actions: lint → test → build → Trivy security scan 
   → publish to Docker Hub on version tags

7. Ansible automation — the whole hardening + deploy process is 
   reproducible on a fresh server in one command

What's not done yet: actual VPN client peers — the server runs, but 
nothing can connect to it until we generate a client config (add-peer.sh 
script).

The real value of the session was less about the specific tools and more 
about debugging real production issues as they came up — Docker 
capability models breaking image startup scripts, a bash operator-
precedence bug, systemd socket activation, Ubuntu/Docker repo version 
mismatches. That's the kind of practical experience that's hard to get 
any other way.
















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





Trivy is a security scanner that runs automatically in our GitHub Actions 
CI pipeline (.github/workflows/ci.yml), in the "scan" job.

It runs in two modes:

1. Image scan — after the Docker image is built, Trivy scans every 
   installed package and library inside it against public CVE databases. 
   If it finds anything rated HIGH or CRITICAL, the build fails, so a 
   vulnerable image never gets published to Docker Hub.

2. Config scan (IaC) — separately, Trivy checks the Dockerfile and 
   docker-compose.yml themselves for unsafe patterns (running as root, 
   missing resource limits, --privileged usage, etc.) — catching mistakes 
   in the setup, not just in installed packages.

Why we needed it: our first build had dozens of CVEs because it shipped 
the entire Go compiler and toolchain inside the final image. After 
switching to a multi-stage Dockerfile (build in one layer, copy only the 
compiled binary to a clean final layer), Trivy's findings dropped from 
dozens down to just a handful — all traced to outdated dependencies 
(golang.org/x/crypto, golang.org/x/net) in the upstream project, which we 
fixed by bumping them to @latest before building.

It only runs in CI (on every push/PR to main), not continuously against 
the already-deployed container — it's a gate before publishing, not a 
runtime monitor.
