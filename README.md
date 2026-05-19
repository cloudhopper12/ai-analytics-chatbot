# AI Analytics Chatbot MVP

One-page analytics workspace with chat, SQL approval, Postgres-backed e-commerce data, and a persistent dashboard.

The intended dev host is `seba@192.168.64.5`, with the project at:

```bash
/home/seba/ai-analytics-chatbot
```

## Current Network Blocker

This Codex session cannot currently reach the dev host:

```bash
ssh seba@192.168.64.5
# ssh: connect to host 192.168.64.5 port 22: No route to host
```

Once SSH routing is fixed, copy or mount this project to `/home/seba/ai-analytics-chatbot` and run the setup commands below on the remote machine.

If you mount the remote home directory on the MacBook, place this folder at:

```text
/home/seba/ai-analytics-chatbot
```

If SSH starts working, a direct copy option is:

```bash
rsync -av --exclude node_modules --exclude .venv ./ seba@192.168.64.5:/home/seba/ai-analytics-chatbot/
```

## Remote Setup

```bash
cd /home/seba/ai-analytics-chatbot
chmod +x scripts/*.sh
./scripts/bootstrap_remote_ubuntu.sh
./scripts/setup_database.sh
./scripts/install_deps.sh
./scripts/run_remote_dev.sh
```

Then open this from the MacBook:

```text
http://192.168.64.5:3000
```

The frontend talks to FastAPI at:

```text
http://192.168.64.5:8000
```

## Useful Questions To Try

- Show monthly revenue.
- What are the top products by revenue?
- Revenue by region.
- Which campaigns are converting?
- Which products need inventory attention?

The MVP uses a deterministic mock agent. It generates SQL previews, waits for approval, then runs read-only queries against Postgres.
