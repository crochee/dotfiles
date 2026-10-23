**Load this reference when:** building or reviewing an MCP server — the shared rules apply in every language, then read the section for the SDK the repository already uses.

# MCP Servers

An MCP server is a tool surface for a model, not a mirror of an HTTP API. The model chooses from names and descriptions, fills a schema it can only read, and recovers from whatever the error says. Design for those three readers.

## Contents

- [The rules that hold in every language](#the-rules-that-hold-in-every-language)
  - [Naming and scope](#naming-and-scope)
  - [Tool descriptions](#tool-descriptions)
  - [Input schemas](#input-schemas)
  - [Annotations](#annotations)
  - [Pagination](#pagination)
  - [Errors the model can act on](#errors-the-model-can-act-on)
  - [Resource or tool](#resource-or-tool)
  - [Transport and auth](#transport-and-auth)
  - [The test harness](#the-test-harness)
- [TypeScript](#typescript)
- [Python](#python)
- [Rust](#rust)
- [Release checklist](#release-checklist)

## The rules that hold in every language

### Naming and scope

- Tool names are `snake_case`, prefixed with the service: `github_create_issue`, `slack_send_message`. The prefix is not decoration — several servers are loaded at once and `create_issue` collides.
- Name with the verb the model would use. `search_users` beats `user_lookup_v2`; `get_user` beats `fetchSingleUserRecord`.
- One tool per intent. If a description needs "and" twice, split it. If two tools differ only by an enum, merge them.
- Prefer a few coarse tools over many thin ones: every tool costs schema tokens on every step. Start with the operations that a real task needs, not with one tool per endpoint.
- No version numbers in names. The server version lives in the package metadata.

### Tool descriptions

The description is what the model reads to decide *whether* and *how* to call. It is not documentation for a human reviewer.

- First sentence: what the tool does and what it returns, in the user's vocabulary.
- Second sentence: when to use this instead of its sibling — the confusing neighbour is the one that gets called wrongly.
- Then the arguments that need context the schema cannot carry (formats, allowed values that are not enumerable).
- One short example call, if the argument shape is unusual.
- State the side effect plainly: "Creates a comment. This is visible to everyone on the issue."

### Input schemas

The schema is the only contract, and the model cannot ask questions about it.

| Rule | Reason |
|---|---|
| Describe every field, including obvious ones | Field descriptions become the schema the model reads; an undescribed field is guessed |
| Constrain types: enums, min/max, length bounds, patterns | A constraint is cheaper than a validation round trip |
| Mark defaults explicitly | An optional field with no default yields `null` at call sites |
| Reject unknown fields where the SDK supports it | Silent typos become silent wrong queries |
| Keep nesting to two levels | Deep objects get filled with plausible nonsense |
| No free-text JSON blob parameter | It defeats validation and the model produces malformed strings |

Return both a machine-readable form and a readable form when the payload is large: structured data for the caller, Markdown for the model to quote. They must agree on values.

### Annotations

| Annotation | `true` when |
|---|---|
| `readOnlyHint` | The tool changes nothing |
| `destructiveHint` | It can delete or overwrite |
| `idempotentHint` | Repeating it with the same arguments adds no effect |
| `openWorldHint` | It reaches an external system |

Annotate every tool, including the read-only ones — a client can auto-approve a read-only tool and must prompt for a destructive one. Annotations are hints; they are not authorization. Enforce permissions in the server.

### Pagination

- Take `limit` (bounded, with a default) and either `offset` or an opaque `cursor`.
- Return the next token (`next_cursor`) only when there is a next page; omit the key on the last page rather than returning null. It is the only end-of-list signal: a second boolean beside it is a second field for one fact, and an HTTP contract that exposes one is `api-design`'s call.
- Never return a full collection and let the client filter. The result is paid for in context on every later step.
- If the upstream cannot report a total, do not invent one. `total: null` is honest; a guessed `total` poisons every downstream count.
- Default page sizes: 20–50 items. A 500-item default is a truncation waiting to happen.

### Errors the model can act on

MCP has two channels, and choosing the wrong one hides the message from the model.

| Channel | Who reads it | Use for |
|---|---|---|
| Tool result with `isError: true` | The model | Validation failures, empty results, upstream 4xx/5xx, rate limits |
| Protocol error (JSON-RPC) | The client application | Unknown tool, malformed request, the server cannot route at all |

A tool error text carries four things:

1. What failed, in terms of the request: `No user matched "ada@example"`.
2. Why, if known: `The search is exact-match on email; partial match requires the query field.`
3. What to do next: `Retry with query="ada" or list_users(domain="example.com").`
4. Whether retrying helps: `Rate limit resets in 30s.` versus `This id does not exist.`

Never leak stack traces, internal hostnames or SQL to the model. Log them server-side, keyed by a request id you can quote without exposing detail.

### Resource or tool

| Use a resource when | Use a tool when |
|---|---|
| The data is addressable by a stable URI | The read needs parameters or search |
| It is read-only and cheap to fetch | There is an action, a side effect, or a mutation |
| The client may pre-load or watch it | The result depends on the caller's intent |

Do not model an action as a resource, and do not expose one tool per file in a corpus. A search tool plus a get-by-id tool beats 400 file resources; the model cannot enumerate 400 options anyway.

### Transport and auth

- **stdio** for local servers launched by the client. Never write logs to stdout — stdout is the protocol stream; log to stderr.
- **Streamable HTTP** for remote or multi-client servers. Prefer a stateless handler so instances scale horizontally; a session held in process memory breaks on the second replica.
- Tokens come from the environment or the request's auth context, never from source. Validate on every request, not only at startup.
- A local HTTP server binds `127.0.0.1` and validates `Origin`; binding `0.0.0.0` exposes an unauthenticated tool surface to the network.
- Cap request body size, time out upstream calls, and propagate cancellation from the client to the upstream request.

### The test harness

A server is tested as a client sees it. One script, run against the built artefact, covering:

1. `tools/list` returns the expected names, and every tool has a description and an input schema.
2. Each tool is called once with valid arguments; the result is non-empty and matches its declared output shape.
3. Each tool is called once with an invalid argument; the result is an error whose text names the offending field and a next action.
4. A list tool is called with `limit` small enough to paginate; the second page is different and `next` is absent on the last page.
5. Two requests are issued concurrently (HTTP transport) or a second session is opened (stdio); both succeed. A server that passes every sequential test and fails this has a shared server instance.
6. A request with a bad token is rejected without a stack trace.

Record the command and its output in the repository; a smoke test nobody runs is documentation, not a test.

## TypeScript

Current stable is the **v2** package `@modelcontextprotocol/server`. The v1 package `@modelcontextprotocol/sdk` still appears in most training data and in older repositories; check `package.json` before importing anything.

| Concern | v2 |
|---|---|
| Package | `@modelcontextprotocol/server`, `zod` `^4.2` |
| Imports | `import { McpServer } from "@modelcontextprotocol/server"` |
| Registration | `server.registerTool(...)`, `registerResource`, `registerPrompt` |
| Schema | `z.object({...})` or `z.strictObject({...})`, described per field |
| stdio | `serveStdio(createServer)` |
| HTTP | `createMcpHandler(createServer)` behind the framework adapter |
| Handler context | `ctx.mcpReq.signal`, `ctx.http?.authInfo` |

```typescript
import { McpServer } from "@modelcontextprotocol/server";
import { serveStdio } from "@modelcontextprotocol/server/stdio";
import * as z from "zod/v4";

const SearchInput = z.strictObject({
  query: z.string().min(2).describe("Text to match against name or email"),
  limit: z.number().int().min(1).max(100).default(20).describe("Maximum rows to return"),
  cursor: z.string().optional().describe("Opaque cursor from a previous page")
});

export function createServer(): McpServer {
  const server = new McpServer({ name: "example-mcp-server", version: "1.0.0" });

  server.registerTool(
    "example_search_users",
    {
      title: "Search users",
      description:
        "Find users by name or email. Returns at most `limit` rows and a `next` cursor. " +
        "Use example_get_user when you already have an id; this tool searches.",
      inputSchema: SearchInput,
      annotations: { readOnlyHint: true, openWorldHint: true }
    },
    async ({ query, limit, cursor }, ctx) => {
      const page = await api.searchUsers(query, { limit, cursor, signal: ctx.mcpReq.signal });
      return {
        content: [{ type: "text", text: renderMarkdown(page) }],
        structuredContent: page,
        isError: false
      };
    }
  );

  return server;
}

serveStdio(createServer);
```

Rules that are easy to get wrong in TypeScript:

- **Return a fresh server per request.** `createMcpHandler(createServer)` calls the factory per HTTP request. A module-scope `McpServer` shared across requests passes sequential tests and fails under concurrency with an opaque internal error.
- **Throw to signal a tool error.** The SDK converts a thrown error into an `isError` result carrying its message; return `{ isError: true, content: [...] }` when you want a custom message without an exception.
- **`structuredContent` must match `outputSchema`** wherever the schema is declared. Build it by parsing the upstream payload through the schema, not by hand-assembling an object.
- **Cap responses by item count.** Shrinking the array keeps `next` pointing at the first omitted row; cutting the text leaves a half-record and a cursor that skips it.
- **Zod 4 differences**: `z.strictObject`, `z.email()`, `z.enum(MyEnum)`. Zod 3 schema shapes fail to type-check against v2.

## Python

The SDK ships FastMCP, which derives the schema from type hints and Pydantic models.

```python
from enum import Enum
from typing import Optional

import httpx
from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, ConfigDict, Field

mcp = FastMCP("example_mcp")
_client = httpx.AsyncClient(base_url="https://api.example.com/v1", timeout=30.0)


class ResponseFormat(str, Enum):
    MARKDOWN = "markdown"
    JSON = "json"


class SearchInput(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    query: str = Field(..., min_length=2, max_length=200, description="Name or email text to match")
    limit: int = Field(20, ge=1, le=100, description="Maximum rows to return")
    cursor: Optional[str] = Field(None, description="Opaque cursor from a previous page")


@mcp.tool(
    name="example_search_users",
    annotations={"title": "Search users", "readOnlyHint": True, "openWorldHint": True},
)
async def example_search_users(params: SearchInput) -> dict:
    """Find users by name or email.

    Returns at most `limit` rows plus `next_cursor`. Use example_get_user
    when you already have an id.
    """
    response = await _client.get("/users", params={"q": params.query, "limit": params.limit})
    response.raise_for_status()
    return response.json()


if __name__ == "__main__":
    mcp.run(transport="stdio")
```

Rules for the Python path:

- The docstring's first paragraph is the tool description; the Pydantic `Field(description=...)` text is the per-field description. Both are read by the model, so write them for the model, not for Sphinx.
- `extra="forbid"` turns a typo into a validation error the model can read instead of a silent default.
- Every tool is `async`; create one `httpx.AsyncClient` at module scope instead of one per call, so connections are pooled and the server does not leak sockets.
- Raising an exception inside a tool produces an error result with the exception message. Raise a short, actionable exception; do not `return "Error: ..."` as a normal result, which reads as success.
- `mcp.run(transport="stdio")` for local; use the streamable HTTP transport for a remote deployment and keep the handler stateless.
- Return a dict or model for structured content; return a rendered string when the payload is for reading. Not both in one field.
- Log via `stderr` (`logging.basicConfig` defaults there); stdout is the protocol stream under stdio.

## Rust

`rmcp` is the official SDK and follows the MCP specification closely. Its macro surface has changed across major versions, so read `Cargo.lock` and the crate's own examples before copying any snippet, including this one.

```rust
use rmcp::{
    handler::server::wrapper::Parameters,
    model::{CallToolResult, ContentBlock},
    schemars, tool, tool_router, ServiceExt,
    transport::stdio,
    ErrorData as McpError,
};
use serde::Deserialize;

#[derive(Debug, Deserialize, schemars::JsonSchema)]
struct SearchUsers {
    /// Name or email text to match.
    query: String,
    /// Maximum rows to return, 1-100.
    #[serde(default = "default_limit")]
    limit: u8,
}

fn default_limit() -> u8 { 20 }

#[derive(Clone)]
struct Example {
    http: reqwest::Client,
}

#[tool_router(server_handler)]
impl Example {
    #[tool(description = "Find users by name or email. Returns at most `limit` rows and a `next` cursor.")]
    async fn example_search_users(
        &self,
        Parameters(args): Parameters<SearchUsers>,
    ) -> Result<CallToolResult, McpError> {
        let page = self
            .http
            .get("https://api.example.com/v1/users")
            .query(&[("q", args.query.as_str()), ("limit", &args.limit.to_string())])
            .send()
            .await
            .map_err(|e| McpError::internal_error(e.to_string(), None))?;

        Ok(CallToolResult::success(vec![ContentBlock::text(
            page.text().await.map_err(|e| McpError::internal_error(e.to_string(), None))?,
        )]))
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let service = Example { http: reqwest::Client::new() }.serve(stdio()).await?;
    service.waiting().await?;
    Ok(())
}
```

- Enable the server feature: `cargo add rmcp --features server`, plus `schemars`, `serde`, `tokio`.
- `Parameters<T>` is the wrapper that carries the deserialized arguments; `T` derives `Deserialize` and `JsonSchema`. Field doc comments become schema descriptions — the only place the model learns what a field means.
- `#[tool_router(server_handler)]` generates a tools-only server handler. When the server also exposes prompts or resources, use `#[tool_router]` plus `#[tool_handler] impl ServerHandler for T` so you can customise capabilities and server info.
- Tool errors: `Ok(CallToolResult::error(vec![ContentBlock::text("...")]))` reaches the model; `Err(McpError)` is a protocol error the model does not see. Use the first for anything the model should recover from.
- Derive `Clone` on the tool struct; the router clones it per session.
- Keep the HTTP client and configuration outside the handler, in the struct, constructed once. A client built per call loses the connection pool and adds a TLS handshake to every step.
- Version drift: the 3.x line unified router and handler attributes; 0.x-era code uses a separate `#[tool_handler]` block and different argument wrappers. Both compile shapes exist in public examples, so match the version in the lockfile.

## Release checklist

- [ ] Tool names are prefixed, snake_case and free of version numbers.
- [ ] Every tool has a description, described fields, annotations, and an error path that names a next action.
- [ ] Every list tool paginates with a bounded `limit`; truncation is visible with the omitted count and the next cursor.
- [ ] The server factory returns a fresh instance per request (HTTP) or per connection (stdio).
- [ ] Auth comes from the environment or the request context; no secret in source; local HTTP binds loopback and validates `Origin`.
- [ ] Logs go to stderr; stdout carries only the protocol.
- [ ] The smoke harness passes: list, valid call, invalid call, pagination, concurrency, bad token.
- [ ] The SDK version in the lockfile matches the idioms in the code.
