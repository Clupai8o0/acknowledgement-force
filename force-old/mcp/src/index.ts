#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { ForceApiError, ForceClient } from "./client.js";

const API_KEY = process.env.FORCE_API_KEY;
const API_BASE = (process.env.FORCE_API_BASE ?? "https://force.app").replace(
  /\/+$/,
  ""
);

if (!API_KEY) {
  // Stay quiet on stdout — that channel is the MCP transport. Errors go to
  // stderr where Claude Desktop / Code show them.
  console.error(
    "[force-mcp] FORCE_API_KEY is not set. Create a key at /settings/api-keys and pass it via env."
  );
  process.exit(1);
}

const client = new ForceClient(API_BASE, API_KEY);

function ok(text: string) {
  return { content: [{ type: "text" as const, text }] };
}
function json(value: unknown) {
  return ok(JSON.stringify(value, null, 2));
}
function fail(err: unknown) {
  const msg =
    err instanceof ForceApiError
      ? `Force API ${err.status}: ${err.message}`
      : err instanceof Error
      ? err.message
      : String(err);
  return { content: [{ type: "text" as const, text: msg }], isError: true };
}

const server = new McpServer({ name: "force", version: "0.1.0" });

server.tool(
  "get_contract",
  "Read the user's daily contract (Markdown).",
  {},
  async () => {
    try {
      const r = await client.getContract();
      return ok(r.contract_md);
    } catch (e) {
      return fail(e);
    }
  }
);

server.tool(
  "update_contract",
  "Replace the entire contract with the provided Markdown.",
  { contract_md: z.string().describe("Full Markdown body of the contract") },
  async ({ contract_md }) => {
    try {
      const r = await client.updateContract(contract_md);
      return ok(`Saved. updated_at=${r.updated_at}`);
    } catch (e) {
      return fail(e);
    }
  }
);

server.tool(
  "append_to_contract",
  "Append text to the end of the contract (with a newline separator). Use this instead of update_contract when you only want to add a section.",
  { text: z.string().describe("Text to append; rendered as Markdown") },
  async ({ text }) => {
    try {
      const current = await client.getContract();
      const sep = current.contract_md.endsWith("\n") ? "" : "\n";
      const next = `${current.contract_md}${sep}${text}`;
      const r = await client.updateContract(next);
      return ok(`Appended. updated_at=${r.updated_at}`);
    } catch (e) {
      return fail(e);
    }
  }
);

server.tool(
  "list_quotes",
  "List every quote the user has saved, as an array of strings.",
  {},
  async () => {
    try {
      const r = await client.listQuotes();
      return json(r.quotes);
    } catch (e) {
      return fail(e);
    }
  }
);

server.tool(
  "add_quote",
  "Append a new quote to the user's list.",
  { text: z.string().describe("The quote text (one line is typical)") },
  async ({ text }) => {
    try {
      const r = await client.addQuote(text);
      return ok(`Added at index ${r.index}. Total: ${r.quotes.length}`);
    } catch (e) {
      return fail(e);
    }
  }
);

server.tool(
  "delete_quote",
  "Remove a quote by its zero-based index. Call list_quotes first to see indices.",
  { index: z.number().int().min(0).describe("Zero-based index from list_quotes") },
  async ({ index }) => {
    try {
      const r = await client.deleteQuote(index);
      return ok(`Removed. ${r.quotes.length} quotes remain.`);
    } catch (e) {
      return fail(e);
    }
  }
);

server.tool(
  "list_goals",
  "List the user's daily goals as { id, label } objects.",
  {},
  async () => {
    try {
      const r = await client.listGoals();
      return json(r.goals);
    } catch (e) {
      return fail(e);
    }
  }
);

const GoalInput = z.object({
  id: z.string().optional(),
  label: z.string(),
});

server.tool(
  "set_goals",
  "Replace the entire goals list. Omit `id` to auto-generate one from the label.",
  { goals: z.array(GoalInput).describe("The new full list of goals, in order") },
  async ({ goals }) => {
    try {
      const r = await client.setGoals(goals);
      return ok(`Saved ${r.goals.length} goal(s).`);
    } catch (e) {
      return fail(e);
    }
  }
);

server.tool(
  "get_reflection",
  "Read the user's free-form reflection.",
  {},
  async () => {
    try {
      const r = await client.getReflection();
      return ok(r.reflection || "(empty)");
    } catch (e) {
      return fail(e);
    }
  }
);

server.tool(
  "set_reflection",
  "Replace the user's reflection with the given text.",
  { reflection: z.string() },
  async ({ reflection }) => {
    try {
      const r = await client.setReflection(reflection);
      return ok(`Saved. updated_at=${r.updated_at}`);
    } catch (e) {
      return fail(e);
    }
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
