"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { BarChart3, CheckCircle2, Database, Loader2, Plus, Play, Send, Trash2 } from "lucide-react";
import { ChartSpec, ResultChart } from "../components/ResultChart";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://192.168.64.5:8000";

type ChatResponse = {
  sessionId: string;
  pendingQueryId: string;
  title: string;
  explanation: string;
  sql: string;
  chartSpec: ChartSpec;
};

type QueryResult = {
  pendingQueryId: string;
  columns: string[];
  rows: Record<string, unknown>[];
  rowCount: number;
};

type AnalysisTurn = ChatResponse & {
  question: string;
  status: "pending" | "executing" | "executed" | "error";
  result?: QueryResult;
  error?: string;
  saved?: boolean;
};

type DashboardWidget = {
  id: string;
  title: string;
  question: string;
  sql: string;
  chartSpec: ChartSpec;
  columns: string[];
  rows: Record<string, unknown>[];
  createdAt: string;
};

const suggestions = [
  "Show monthly revenue",
  "Top products by revenue",
  "Revenue by region",
  "Which campaigns are converting?",
  "Which products need inventory attention?"
];

export default function Home() {
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [question, setQuestion] = useState("");
  const [turns, setTurns] = useState<AnalysisTurn[]>([]);
  const [dashboard, setDashboard] = useState<DashboardWidget[]>([]);
  const [isAsking, setIsAsking] = useState(false);
  const [dashboardLoading, setDashboardLoading] = useState(true);
  const [pageError, setPageError] = useState<string | null>(null);

  const latestRows = useMemo(() => dashboard.reduce((total, widget) => total + widget.rows.length, 0), [dashboard]);

  useEffect(() => {
    loadDashboard();
  }, []);

  async function loadDashboard() {
    setDashboardLoading(true);
    try {
      const response = await fetch(`${API_URL}/dashboard`);
      if (!response.ok) {
        throw new Error(await response.text());
      }
      const payload = (await response.json()) as { widgets: DashboardWidget[] };
      setDashboard(payload.widgets);
      setPageError(null);
    } catch (error) {
      setPageError(error instanceof Error ? error.message : "Unable to load dashboard.");
    } finally {
      setDashboardLoading(false);
    }
  }

  async function askQuestion(nextQuestion?: string) {
    const text = (nextQuestion ?? question).trim();
    if (!text || isAsking) {
      return;
    }

    setIsAsking(true);
    setQuestion("");
    setPageError(null);

    try {
      const response = await fetch(`${API_URL}/chat`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ question: text, sessionId })
      });

      if (!response.ok) {
        throw new Error(await response.text());
      }

      const payload = (await response.json()) as ChatResponse;
      setSessionId(payload.sessionId);
      setTurns((current) => [{ ...payload, question: text, status: "pending" }, ...current]);
    } catch (error) {
      setPageError(error instanceof Error ? error.message : "Unable to ask the agent.");
    } finally {
      setIsAsking(false);
    }
  }

  async function approveQuery(pendingQueryId: string) {
    setTurns((current) =>
      current.map((turn) => (turn.pendingQueryId === pendingQueryId ? { ...turn, status: "executing", error: undefined } : turn))
    );

    try {
      const response = await fetch(`${API_URL}/queries/${pendingQueryId}/approve`, { method: "POST" });
      if (!response.ok) {
        throw new Error(await response.text());
      }
      const result = (await response.json()) as QueryResult;
      setTurns((current) =>
        current.map((turn) => (turn.pendingQueryId === pendingQueryId ? { ...turn, status: "executed", result } : turn))
      );
    } catch (error) {
      setTurns((current) =>
        current.map((turn) =>
          turn.pendingQueryId === pendingQueryId
            ? { ...turn, status: "error", error: error instanceof Error ? error.message : "Query failed." }
            : turn
        )
      );
    }
  }

  async function saveToDashboard(turn: AnalysisTurn) {
    if (!turn.result) {
      return;
    }

    try {
      const response = await fetch(`${API_URL}/dashboard/widgets`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: turn.title,
          question: turn.question,
          sql: turn.sql,
          chartSpec: turn.chartSpec,
          columns: turn.result.columns,
          rows: turn.result.rows
        })
      });

      if (!response.ok) {
        throw new Error(await response.text());
      }

      const widget = (await response.json()) as DashboardWidget;
      setDashboard((current) => [widget, ...current]);
      setTurns((current) => current.map((item) => (item.pendingQueryId === turn.pendingQueryId ? { ...item, saved: true } : item)));
    } catch (error) {
      setPageError(error instanceof Error ? error.message : "Unable to save dashboard widget.");
    }
  }

  async function deleteWidget(widgetId: string) {
    const previous = dashboard;
    setDashboard((current) => current.filter((widget) => widget.id !== widgetId));

    try {
      const response = await fetch(`${API_URL}/dashboard/widgets/${widgetId}`, { method: "DELETE" });
      if (!response.ok) {
        throw new Error(await response.text());
      }
    } catch (error) {
      setDashboard(previous);
      setPageError(error instanceof Error ? error.message : "Unable to delete dashboard widget.");
    }
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    askQuestion();
  }

  return (
    <main className="min-h-screen bg-cloud text-ink">
      <div className="mx-auto flex w-full max-w-[1500px] flex-col gap-5 px-5 py-5 lg:px-7">
        <header className="flex flex-col gap-3 border-b border-stone-200 pb-5 md:flex-row md:items-center md:justify-between">
          <div>
            <div className="flex items-center gap-2 text-sm font-semibold uppercase tracking-wide text-harbor">
              <Database className="h-4 w-4" />
              Postgres analytics agent
            </div>
            <h1 className="mt-2 text-3xl font-semibold text-ink">AI Analytics Chatbot</h1>
          </div>
          <div className="grid grid-cols-2 gap-3 text-sm md:min-w-[360px]">
            <Stat label="Dashboard widgets" value={dashboard.length.toString()} />
            <Stat label="Saved rows" value={latestRows.toString()} />
          </div>
        </header>

        {pageError ? (
          <div className="rounded border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">{pageError}</div>
        ) : null}

        <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_440px]">
          <section className="flex min-h-[calc(100vh-160px)] flex-col rounded border border-stone-200 bg-white shadow-soft">
            <div className="border-b border-stone-200 px-5 py-4">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <h2 className="text-lg font-semibold">Chat analysis</h2>
                  <p className="text-sm text-stone-500">Ask a question, approve SQL, then pin the result.</p>
                </div>
                <BarChart3 className="h-5 w-5 text-berry" />
              </div>
            </div>

            <div className="flex-1 space-y-4 overflow-auto px-5 py-5">
              <div className="flex flex-wrap gap-2">
                {suggestions.map((suggestion) => (
                  <button
                    key={suggestion}
                    type="button"
                    onClick={() => askQuestion(suggestion)}
                    className="rounded border border-stone-200 bg-stone-50 px-3 py-2 text-sm text-stone-700 transition hover:border-harbor hover:text-harbor"
                  >
                    {suggestion}
                  </button>
                ))}
              </div>

              {turns.length === 0 ? (
                <div className="flex min-h-72 items-center justify-center rounded border border-dashed border-stone-300 bg-stone-50 px-6 text-center text-stone-500">
                  Ask an e-commerce analytics question to generate a SQL preview.
                </div>
              ) : (
                turns.map((turn) => (
                  <AnalysisCard key={turn.pendingQueryId} turn={turn} onApprove={approveQuery} onSave={saveToDashboard} />
                ))
              )}
            </div>

            <form onSubmit={handleSubmit} className="border-t border-stone-200 bg-stone-50 p-4">
              <div className="flex gap-3">
                <input
                  value={question}
                  onChange={(event) => setQuestion(event.target.value)}
                  placeholder="Ask about revenue, products, campaigns, margin, or inventory"
                  className="min-w-0 flex-1 rounded border border-stone-300 bg-white px-4 py-3 text-sm outline-none transition focus:border-harbor focus:ring-2 focus:ring-harbor/15"
                />
                <button
                  type="submit"
                  disabled={isAsking || !question.trim()}
                  className="inline-flex h-12 items-center gap-2 rounded bg-ink px-4 text-sm font-semibold text-white transition hover:bg-harbor disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {isAsking ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
                  Ask
                </button>
              </div>
            </form>
          </section>

          <aside className="rounded border border-stone-200 bg-white shadow-soft lg:sticky lg:top-5 lg:max-h-[calc(100vh-40px)] lg:overflow-hidden">
            <div className="border-b border-stone-200 px-5 py-4">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <h2 className="text-lg font-semibold">My Dashboard</h2>
                  <p className="text-sm text-stone-500">Saved charts return whenever this page opens.</p>
                </div>
                <CheckCircle2 className="h-5 w-5 text-harbor" />
              </div>
            </div>
            <div className="space-y-4 overflow-auto p-5 lg:max-h-[calc(100vh-130px)]">
              {dashboardLoading ? (
                <div className="flex h-40 items-center justify-center text-sm text-stone-500">
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Loading dashboard
                </div>
              ) : dashboard.length === 0 ? (
                <div className="rounded border border-dashed border-stone-300 bg-stone-50 px-4 py-8 text-center text-sm text-stone-500">
                  Approved chat results can be added here with the Add to dashboard button.
                </div>
              ) : (
                dashboard.map((widget) => (
                  <div key={widget.id} className="rounded border border-stone-200 bg-stone-50 p-4">
                    <div className="mb-3 flex items-start justify-between gap-3">
                      <div>
                        <h3 className="text-sm font-semibold text-ink">{widget.title}</h3>
                        <p className="mt-1 line-clamp-2 text-xs text-stone-500">{widget.question}</p>
                      </div>
                      <button
                        type="button"
                        onClick={() => deleteWidget(widget.id)}
                        aria-label={`Delete ${widget.title}`}
                        className="rounded p-1 text-stone-400 transition hover:bg-white hover:text-rose-600"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                    <ResultChart chartSpec={widget.chartSpec} rows={widget.rows} columns={widget.columns} compact />
                  </div>
                ))
              )}
            </div>
          </aside>
        </div>
      </div>
    </main>
  );
}

function AnalysisCard({
  turn,
  onApprove,
  onSave
}: {
  turn: AnalysisTurn;
  onApprove: (pendingQueryId: string) => void;
  onSave: (turn: AnalysisTurn) => void;
}) {
  return (
    <article className="rounded border border-stone-200 bg-white p-4 shadow-sm">
      <div className="mb-4 rounded bg-stone-100 px-4 py-3">
        <p className="text-xs font-semibold uppercase tracking-wide text-stone-500">Question</p>
        <p className="mt-1 text-sm text-stone-800">{turn.question}</p>
      </div>

      <div className="flex flex-col gap-4">
        <div>
          <div className="flex items-start justify-between gap-3">
            <div>
              <h3 className="text-base font-semibold">{turn.title}</h3>
              <p className="mt-1 text-sm text-stone-600">{turn.explanation}</p>
            </div>
            <StatusPill status={turn.status} />
          </div>
        </div>

        <div>
          <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-stone-500">SQL preview</p>
          <pre className="max-h-56 overflow-auto rounded bg-ink p-4 text-xs leading-relaxed text-stone-100">{turn.sql}</pre>
        </div>

        {turn.status === "pending" ? (
          <button
            type="button"
            onClick={() => onApprove(turn.pendingQueryId)}
            className="inline-flex w-fit items-center gap-2 rounded bg-harbor px-4 py-2 text-sm font-semibold text-white transition hover:bg-ink"
          >
            <Play className="h-4 w-4" />
            Approve and run
          </button>
        ) : null}

        {turn.status === "executing" ? (
          <div className="inline-flex items-center text-sm text-stone-500">
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            Running approved SQL
          </div>
        ) : null}

        {turn.error ? <div className="rounded border border-rose-200 bg-rose-50 px-3 py-2 text-sm text-rose-700">{turn.error}</div> : null}

        {turn.result ? (
          <div className="space-y-3">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <p className="text-sm text-stone-500">{turn.result.rowCount} rows returned</p>
              <button
                type="button"
                onClick={() => onSave(turn)}
                disabled={turn.saved}
                className="inline-flex w-fit items-center gap-2 rounded bg-berry px-4 py-2 text-sm font-semibold text-white transition hover:bg-ink disabled:cursor-not-allowed disabled:bg-stone-300"
              >
                {turn.saved ? <CheckCircle2 className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
                {turn.saved ? "Added to dashboard" : "Add to dashboard"}
              </button>
            </div>
            <ResultChart chartSpec={turn.chartSpec} rows={turn.result.rows} columns={turn.result.columns} />
          </div>
        ) : null}
      </div>
    </article>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded border border-stone-200 bg-white px-4 py-3 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-wide text-stone-500">{label}</p>
      <p className="mt-1 text-xl font-semibold text-ink">{value}</p>
    </div>
  );
}

function StatusPill({ status }: { status: AnalysisTurn["status"] }) {
  const label = {
    pending: "Needs approval",
    executing: "Running",
    executed: "Preview ready",
    error: "Error"
  }[status];

  const color = {
    pending: "border-saffron/30 bg-saffron/10 text-stone-800",
    executing: "border-harbor/30 bg-harbor/10 text-harbor",
    executed: "border-harbor/30 bg-harbor/10 text-harbor",
    error: "border-rose-200 bg-rose-50 text-rose-700"
  }[status];

  return <span className={`whitespace-nowrap rounded border px-2 py-1 text-xs font-semibold ${color}`}>{label}</span>;
}
