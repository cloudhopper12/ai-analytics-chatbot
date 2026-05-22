# AI Analytics Chatbot

AI Analytics Chatbot is a local-first analytics workspace where a user can ask business questions in a chat interface, review the generated SQL, approve the query, and save the resulting chart or table to a persistent dashboard.

The current MVP uses a deterministic mock agent instead of a live LLM provider. That means the app works without an API key while still demonstrating the full product flow: chat, SQL preview, approval, Postgres query execution, chart rendering, and dashboard persistence.

## What It Does

- Provides a one-page web app with chat and dashboard side by side.
- Accepts natural-language e-commerce analytics questions.
- Generates a SQL preview for supported question types.
- Requires the user to approve SQL before it runs.
- Executes approved read-only SQL against Postgres.
- Renders results as charts or tables.
- Lets users save chat results to a persistent dashboard.
- Reloads saved dashboard widgets whenever the webpage opens.

Useful example questions:

- Show monthly revenue.
- What are the top products by revenue?
- Revenue by region.
- Which campaigns are converting?
- Which products need inventory attention?
- Show monthly gross margin.

## Architecture

```text
apps/web        Next.js + TypeScript frontend
services/api    FastAPI backend, mock agent, SQL guardrails, dashboard API
database        Postgres schema and deterministic e-commerce seed data
scripts         Setup, install, run, and smoke-test helpers
```

Runtime flow:

```text
User question
-> Next.js sends POST /chat
-> FastAPI mock agent returns SQL preview and chart spec
-> User approves SQL in the UI
-> FastAPI validates and runs read-only SQL
-> UI renders chart/table preview
-> User clicks Add to dashboard
-> FastAPI saves dashboard widget in Postgres
-> Dashboard reloads saved widgets on future visits
```

## Prerequisites

Recommended development environment:

- Ubuntu/Debian Linux
- Node.js 18 or newer
- npm
- Python 3.12 or newer
- PostgreSQL 16 or newer
- Git
- tmux, optional but useful for running both dev servers

The included setup scripts are written for Ubuntu/Debian. Other operating systems can run the project too, but you may need to install dependencies and initialize Postgres manually.

## Quick Start

Clone the repository:

```bash
git clone https://github.com/cloudhopper12/ai-analytics-chatbot.git
cd ai-analytics-chatbot
```

On Ubuntu/Debian, install system dependencies:

```bash
chmod +x scripts/*.sh
./scripts/bootstrap_remote_ubuntu.sh
```

Create and seed the database:

```bash
./scripts/setup_database.sh
```

Install application dependencies:

```bash
./scripts/install_deps.sh
```

Start the API and web app for local development:

```bash
REMOTE_HOST=localhost ./scripts/run_remote_dev.sh
```

Open the web app:

```text
http://localhost:3000
```

The API runs on:

```text
http://localhost:8000
```

## Running On A Remote Machine Or VM

If you run the app on a remote host or VM and want to access it from another computer, start the dev servers with the host IP:

```bash
REMOTE_HOST=<server-ip> ./scripts/run_remote_dev.sh
```

Then open:

```text
http://<server-ip>:3000
```

The frontend will call the API at:

```text
http://<server-ip>:8000
```

Make sure ports `3000` and `8000` are reachable from your browser machine.

## Configuration

The backend reads these environment variables:

```bash
APP_DATABASE_URL=postgresql://analytics_app:<generated-app-password>@localhost:5432/analytics_chatbot
ANALYTICS_DATABASE_URL=postgresql://analytics_readonly:<generated-readonly-password>@localhost:5432/analytics_chatbot
WEB_ORIGIN=http://localhost:3000
MAX_QUERY_ROWS=500
STATEMENT_TIMEOUT_MS=5000
```

The frontend reads:

```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
```

Example env files are included:

```text
services/api/.env.example
apps/web/.env.local.example
```

The run script derives `WEB_ORIGIN` and `NEXT_PUBLIC_API_URL` from `REMOTE_HOST` unless you override them explicitly.

## Database

The setup script creates local development roles, generates local-only passwords, writes ignored env files, and creates a database:

- Database: `analytics_chatbot`
- App role: `analytics_app`
- Read-only analytics role: `analytics_readonly`

Generated local passwords are written to ignored env files. Do not commit real credentials, and rotate them before using the project in any shared or production-like environment.

The analytics schema includes seeded e-commerce data for:

- categories
- products
- customers
- orders
- order items
- payments
- campaigns
- web sessions
- inventory snapshots

The app schema stores:

- chat sessions
- pending SQL approvals
- saved dashboard widgets

To reset the seeded analytics data:

```bash
./scripts/setup_database.sh
```

For manual Postgres setup, create the database roles first, then apply:

```bash
psql -d analytics_chatbot -f database/schema.sql
psql -d analytics_chatbot -f database/seed.sql
```

## Development Commands

Run the backend tests:

```bash
cd services/api
PYTHONPATH=. .venv/bin/python -m pytest tests -q
```

Build the frontend:

```bash
npm --workspace apps/web run build
```

Run only the API:

```bash
cd services/api
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Run only the web app:

```bash
NEXT_PUBLIC_API_URL=http://localhost:8000 npm run dev:web
```

Run a smoke test against a remote host:

```bash
REMOTE_HOST=<server-ip> ./scripts/remote_smoke_test.sh
```

## Safety And Access Controls

- Generated SQL must pass read-only validation and user approval before execution.
- The analytics query role only has `SELECT` access to analytics tables.
- The app role has limited app-schema permissions and no broad table-level delete grant.
- Dashboard removals are soft deletes (`deleted_at`) and require a browser confirmation.
- For GitHub, prefer pull requests and branch protection. Keep deploy keys read-only unless a controlled automation needs temporary write access.

## Notes

- The current agent is intentionally deterministic. It maps supported question types to predefined SQL templates in `services/api/app/mock_agent.py`.
- SQL approval is required before any analytics query runs.
- Query execution uses a read-only Postgres role and a statement timeout.
- Saved dashboard widgets store result snapshots, so the dashboard can reload without rerunning SQL.
- A future version can replace the mock agent with an LLM-backed agent while keeping the existing SQL approval and dashboard flow.

## Contribution Workflow

Future Codex work must not happen directly on `main`.

Required workflow:

1. Start from an up-to-date `main` branch.
2. Create a feature branch, for example `codex/<short-change-name>`.
3. Commit changes only on that feature branch.
4. Push only the feature branch.
5. Open a pull request for manual review.
6. Merge to `main` only after the user reviews and approves the change.

This repository includes a local `pre-push` hook template in `.githooks/pre-push` that blocks direct pushes from or to `main`. Enable it after cloning with:

```bash
git config core.hooksPath .githooks
```
