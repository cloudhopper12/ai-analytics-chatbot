"use client";

import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis
} from "recharts";

export type ChartSpec = {
  kind: "bar" | "line" | "table";
  title: string;
  xKey: string;
  yKey: string;
  valueLabel?: string;
};

type ResultChartProps = {
  chartSpec: ChartSpec;
  rows: Record<string, unknown>[];
  columns: string[];
  compact?: boolean;
};

export function ResultChart({ chartSpec, rows, columns, compact = false }: ResultChartProps) {
  if (!rows.length) {
    return (
      <div className="flex h-36 items-center justify-center rounded border border-dashed border-stone-300 bg-white/70 text-sm text-stone-500">
        No rows returned
      </div>
    );
  }

  if (chartSpec.kind === "table") {
    return <DataTable rows={rows} columns={columns} compact={compact} />;
  }

  const height = compact ? 190 : 250;
  const tickStyle = { fontSize: 11, fill: "#59666c" };
  const shortTick = (value: unknown) => {
    const text = String(value);
    return text.length > 14 ? `${text.slice(0, 12)}...` : text;
  };

  return (
    <div className="h-[250px] w-full rounded border border-stone-200 bg-white p-3 shadow-sm" style={{ height }}>
      <ResponsiveContainer width="100%" height="100%">
        {chartSpec.kind === "line" ? (
          <LineChart data={rows} margin={{ top: 12, right: 18, bottom: 8, left: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e7e2d8" />
            <XAxis dataKey={chartSpec.xKey} tick={tickStyle} interval={0} tickMargin={8} tickFormatter={shortTick} />
            <YAxis tick={tickStyle} width={52} />
            <Tooltip />
            <Line
              type="monotone"
              dataKey={chartSpec.yKey}
              name={chartSpec.valueLabel ?? chartSpec.yKey}
              stroke="#167c80"
              strokeWidth={3}
              dot={{ r: 4, fill: "#167c80" }}
            />
          </LineChart>
        ) : (
          <BarChart data={rows} margin={{ top: 12, right: 18, bottom: 8, left: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e7e2d8" />
            <XAxis dataKey={chartSpec.xKey} tick={tickStyle} interval={0} tickMargin={8} tickFormatter={shortTick} />
            <YAxis tick={tickStyle} width={52} />
            <Tooltip />
            <Bar dataKey={chartSpec.yKey} name={chartSpec.valueLabel ?? chartSpec.yKey} fill="#167c80" radius={[4, 4, 0, 0]} />
          </BarChart>
        )}
      </ResponsiveContainer>
    </div>
  );
}

function DataTable({ rows, columns, compact }: { rows: Record<string, unknown>[]; columns: string[]; compact: boolean }) {
  const visibleColumns = compact ? columns.slice(0, 4) : columns;

  return (
    <div className="max-h-72 overflow-auto rounded border border-stone-200 bg-white shadow-sm">
      <table className="min-w-full text-left text-sm">
        <thead className="sticky top-0 bg-stone-100 text-xs uppercase tracking-wide text-stone-500">
          <tr>
            {visibleColumns.map((column) => (
              <th key={column} className="whitespace-nowrap px-3 py-2 font-semibold">
                {column.replaceAll("_", " ")}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-stone-100">
          {rows.map((row, index) => (
            <tr key={index}>
              {visibleColumns.map((column) => (
                <td key={column} className="whitespace-nowrap px-3 py-2 text-stone-700">
                  {String(row[column] ?? "")}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
