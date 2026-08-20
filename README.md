# Order Workspace

A [Ballerina workspace](https://ballerina.io/learn/workspaces/) holding the three WSO2 Integrator: BI
integration types — an **Integration as API**, an **AI Agent**, and an **Automation** — plus the shared library
they are all built on.

Requires **Ballerina 2201.13.0 or later** (`[workspace]` support landed in Update 13).

## Layout

```
order-workspace/
├── Ballerina.toml            # [workspace] section only
├── order_commons/            # library  — shared records and pure functions
│   ├── types.bal
│   └── calculations.bal
├── orders_api/               # Integration as API   → http:Listener on :9090
│   ├── service.bal
│   └── store.bal
├── order_agent/              # AI Agent             → ai:Listener on :9091
│   ├── agent.bal
│   └── tools.bal
└── daily_summary/            # Automation           → public function main
    └── main.bal
```

```toml
[workspace]
packages = ["order_commons", "orders_api", "order_agent", "daily_summary"]
```

All four packages share the org `gabilan`; a workspace resolves to a single organization.

## How the packages depend on each other

Two layers.

**Compile time.** Every integration does `import gabilan/order_commons as commons;` for the shared
`PurchaseOrder`, `OrderItem`, `OrderRequest`, `OrderSummary` and `StatusUpdate` records, plus
`calculateOrderTotal` and `summarizeOrders`. The workspace resolves these directly from the sibling directory —
`order_commons` is never published to Ballerina Central.

**Runtime.** The integrations call each other over HTTP:

```
daily_summary ──HTTP──> order_agent ──HTTP──> orders_api
      └────────────────────HTTP────────────────────┘
```

- `order_agent` exposes four `@ai:AgentTool` functions — `listPendingOrders`, `getOrderDetails`,
  `getOrderSummary`, `shipOrder` — each of which is an HTTP call into `orders_api`.
- `daily_summary` reads the order book from `orders_api`, computes the figures locally with
  `commons:summarizeOrders`, then asks `order_agent` to narrate them. If the agent is unreachable it logs a
  warning and still prints the figures.

### Why the shared library, instead of the integrations importing each other

The workspace documentation states: *"Executables are produced only for packages that are not dependencies of
other workspace packages."* Had `order_agent` imported `orders_api` directly, `orders_api` would stop producing
an executable and its `http:Listener` would boot inside the agent's process — one deployable unit instead of
three. Keeping the compile-time dependency on a listener-free library, and the integration-to-integration
dependency over HTTP, keeps all three independently deployable.

`bal build` demonstrates the rule: three jars, and none for `order_commons`.

## Build

```bash
bal build                 # every package in the workspace
bal build orders_api      # a single member, resolved from the workspace
```

Expected output:

```
orders_api/target/bin/orders_api.jar
order_agent/target/bin/order_agent.jar
daily_summary/target/bin/daily_summary.jar
```

`order_commons` produces no executable — it is a dependency of the other three.

## Configuration

Each integration declares required `configurable` variables with no defaults, supplied through a per-package
`Config.toml` (gitignored).

| Package | Variable | Example |
|---|---|---|
| `orders_api` | `servicePort` | `9090` |
| `order_agent` | `agentPort` | `9091` |
| | `ordersApiUrl` | `"http://localhost:9090/orders"` |
| | `openAiApiKey` | *your OpenAI key* |
| `daily_summary` | `ordersApiUrl` | `"http://localhost:9090/orders"` |
| | `orderAgentUrl` | `"http://localhost:9091/orderAgent"` |

The agent uses `ballerinax/ai.openai` with `GPT_4O_MINI`; swap the model provider in `order_agent/agent.bal` to
use a different LLM.

## Run

`bal run <package>` from the workspace root looks for `Config.toml` in the root, not in the member directory, so
point it at the right file:

```bash
# terminal A — the API integration
BAL_CONFIG_FILES=$PWD/orders_api/Config.toml bal run orders_api

# terminal B — the AI agent
BAL_CONFIG_FILES=$PWD/order_agent/Config.toml bal run order_agent

# terminal C — the automation
BAL_CONFIG_FILES=$PWD/daily_summary/Config.toml bal run daily_summary
```

Running from inside a package directory works too, and picks up that package's `Config.toml` automatically.

## Try it

Seed a couple of orders:

```bash
curl -X POST localhost:9090/orders -H 'Content-Type: application/json' \
  -d '{"customerName":"Acme Traders","orderItems":[{"itemCode":"KB-01","itemQuantity":2,"itemPrice":25.00}]}'

curl -X POST localhost:9090/orders -H 'Content-Type: application/json' \
  -d '{"customerName":"Belmont Retail","orderItems":[{"itemCode":"MN-24","itemQuantity":3,"itemPrice":180.00}]}'

curl localhost:9090/orders
curl localhost:9090/orders/summary
```

Ask the agent — a correct answer here proves it invoked its tool against the running API integration:

```bash
curl -X POST localhost:9091/orderAgent/chat -H 'Content-Type: application/json' \
  -d '{"sessionId":"s1","message":"Which orders are still pending, and which is worth the most?"}'
```

Then run the automation, which pulls from both:

```
=== Daily order summary ===
Total orders   : 2
Pending orders : 1
Total value    : 605.500
--- Agent narrative ---
...
```

## API reference

`orders_api`, base path `/orders`:

| Method | Path | Body | Returns |
|---|---|---|---|
| `GET` | `/orders` | — | `PurchaseOrder[]` |
| `GET` | `/orders/summary` | — | `OrderSummary` |
| `GET` | `/orders/{orderId}` | — | `PurchaseOrder` or `404` |
| `POST` | `/orders` | `OrderRequest` | the created `PurchaseOrder` |
| `PATCH` | `/orders/{orderId}/status` | `StatusUpdate` | the updated `PurchaseOrder` or `404` |

`order_agent`, base path `/orderAgent`:

| Method | Path | Body | Returns |
|---|---|---|---|
| `POST` | `/orderAgent/chat` | `{"sessionId": "...", "message": "..."}` | `{"message": "..."}` |

Orders are held in an in-memory `table` in `orders_api/store.bal` and are lost on restart.

## Notes

- One transitive dependency, `ballerinax/openai.embeddings:1.0.6`, predates Update 12 and raises a build
  warning. Use `bal build --locking-mode=soft` if it causes trouble.
- `Dependencies.toml` is generated by the build tool — do not hand-edit it.
