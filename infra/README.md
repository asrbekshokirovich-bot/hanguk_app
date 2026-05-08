# `infra/` — uni_db worker host provisioning

Source-of-truth files for the always-on Hetzner CX22 host that runs
the uni_db crawler / extractor / OCR / translation workers. The
operator runbook is at
[`docs/runbooks/hetzner-provisioning.md`](../docs/runbooks/hetzner-provisioning.md).

## Layout

```
infra/
├── README.md
├── bootstrap.sh         # idempotent first-boot hardening
├── deploy.sh            # rsync from local checkout + venv install + restart
├── env.example          # /etc/uni_db/env template
└── systemd/
    ├── uni-db-discovery-poll.service
    ├── uni-db-discovery-poll.timer
    ├── uni-db-extract.service
    ├── uni-db-translate.service
    └── uni-db-ocr.service
```

## Conventions

- Service account: `uni-db` (system, no shell)
- Repo on host: `/opt/uni_db/`
- venv: `/opt/uni_db/services/uni_db/.venv/`
- Caches: `/var/cache/uni_db/`
- Logs: journald (no app-level logfiles)
- Secrets: `/etc/uni_db/env` (mode 640, group `uni-db`)
- systemd unit naming: `uni-db-*.{service,timer}`

## Why the host has no application state

By design — losing the VM is recoverable in 10 minutes via this
directory plus the runbook. Everything stateful lives in Supabase
Postgres + Storage. See ADR-003.
