# Kiosk JSON API

An internal, read/write JSON API for clients and settlements. It exposes the
whole settlement workflow: look up clients, create a settlement with its
positions, edit it, complete it, and send the settlement email.

Everything lives under `/api` and speaks JSON only — no HTML, no cookies, no
CSRF token.

## Authentication

Every request needs a static bearer token:

```
Authorization: Bearer <token>
```

The `Token` scheme (`Authorization: Token token="<token>"`) works as well.

### Server side

The token lives in the Rails credentials under `api.token`, with `ENV["API_TOKEN"]`
as a fallback (credentials win when both are set):

```yaml
api:
  token: 4f1b…   # generate with `bin/rails secret`
```

```bash
bin/rails credentials:edit                          # development
bin/rails credentials:edit --environment production # production
```

Note that production reads `config/credentials/production.yml.enc`, not the
default credentials file — so a production deploy needs the token either in the
production credentials or as `API_TOKEN` in the container environment.

Without a configured token the API answers `503 Service Unavailable` with
`{"error": "api_not_configured"}` — every endpoint, so a missing credential can
never be mistaken for an open API.

Wrong or missing token ⇒ `401 Unauthorized`.

The token grants full access to all endpoints below; there is no per-client
scoping. Treat it like the admin password.

### Client side

Callers read the token from `ENV["API_TOKEN"]`. Locally that comes from `.env`
(gitignored, loaded by `bin/dev` and `script/api`):

```
API_TOKEN=4f1b…
KIOSK_API_URL=http://localhost:3050   # optional, defaults to https://kiosk.grekko.de
```

## Conventions

- Base URL: `https://<host>/api` (locally `http://localhost:3050/api`).
- Request bodies are JSON; send `Content-Type: application/json`.
- All amounts are integers in **cents**. All timestamps are ISO 8601;
  `generated_at` is a plain date (`YYYY-MM-DD`).
- Successful responses wrap the payload in a top-level key (`clients`,
  `settlement`, `position`, …).
- A settlement's `state` is one of `draft`, `completed`, `paid`.

### Errors

Errors always look like this:

```json
{
  "error": "validation_failed",
  "message": "Client must have an email address",
  "details": { "base": ["Client must have an email address"] }
}
```

`details` is only present on validation errors.

| Status | `error`               | Meaning                                                        |
| ------ | --------------------- | -------------------------------------------------------------- |
| 400    | `parameter_missing`   | Required top-level key (e.g. `settlement`) missing from the body |
| 401    | `unauthorized`        | Missing or wrong token                                          |
| 404    | `not_found`           | Unknown id                                                      |
| 422    | `validation_failed`   | Record invalid (unknown `client_id`, missing `generated_at`, …) |
| 422    | `invalid_transition`  | State machine refused the transition (e.g. completing twice)    |
| 503    | `api_not_configured`  | No `api.token` in the credentials                               |

## Endpoints

### `GET /api/clients`

Lists all clients.

Query parameters:

| Name     | Description                                     |
| -------- | ----------------------------------------------- |
| `active` | `true` returns only clients that are not suspended |

```bash
curl -H "Authorization: Bearer $KIOSK_API_TOKEN" \
     https://kiosk.example.com/api/clients
```

```json
{
  "clients": [
    { "id": 1, "name": "Alice", "email": "alice@example.com", "suspended": false },
    { "id": 2, "name": "Bob", "email": null, "suspended": true }
  ]
}
```

A client without an `email` cannot receive settlement mails — `send_email` will
return `422` for it.

### `GET /api/drinks`

Lists drinks, needed to build settlement positions.

```json
{
  "drinks": [
    {
      "id": 7,
      "name": "Pils",
      "price_in_cents": 120,
      "current_settlement_price_in_cents": 150
    }
  ]
}
```

`current_settlement_price_in_cents` is what a position created today would be
priced at (`price_in_cents` unless a settlement price overrides it). Positions
are priced from the drink price valid at the settlement's `generated_at`, so a
backdated settlement may use a different price.

### `GET /api/monthly_reports`

Lists monthly reports, newest first. Every settlement belongs to one.

```json
{
  "monthly_reports": [
    { "id": 4, "title": "Januar 2026", "description": "…", "created_at": "2026-02-01T09:00:00Z" }
  ]
}
```

Monthly reports are created in the web UI; the API is read-only here.

### `GET /api/settlements`

Lists settlements, newest first, each with its positions.

Query parameters: `client_id`, `monthly_report_id`, `state`
(`draft` | `completed` | `paid`).

```bash
curl -H "Authorization: Bearer $KIOSK_API_TOKEN" \
     "https://kiosk.example.com/api/settlements?client_id=1&state=draft"
```

### `GET /api/settlements/:id`

Returns one settlement.

```json
{
  "settlement": {
    "id": 42,
    "state": "draft",
    "client_id": 1,
    "client_name": "Alice",
    "monthly_report_id": 4,
    "monthly_report_title": "Januar 2026",
    "generated_at": "2026-01-31",
    "completed_at": null,
    "paid_at": null,
    "email_sent_at": null,
    "email_first_opened_at": null,
    "price_in_cents": 360,
    "positions": [
      {
        "id": 91,
        "settlement_id": 42,
        "drink_id": 7,
        "drink_name": "Pils",
        "amount": 3,
        "price_in_cents": 360
      }
    ]
  }
}
```

`price_in_cents` on the settlement is the sum of its positions.

### `POST /api/settlements`

Creates a settlement, optionally with its positions in the same call. Positions
are priced by the server; sending a price is not possible.

| Field                          | Required | Notes                                   |
| ------------------------------ | -------- | --------------------------------------- |
| `settlement.client_id`         | yes      |                                         |
| `settlement.monthly_report_id` | yes      |                                         |
| `settlement.generated_at`      | yes      | `YYYY-MM-DD`, drives position pricing   |
| `settlement.paid_at`           | no       | Timestamp; normally set through payments |
| `settlement.positions[]`       | no       | `drink_id` + `amount`                   |

```bash
curl -X POST \
     -H "Authorization: Bearer $KIOSK_API_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
           "settlement": {
             "client_id": 1,
             "monthly_report_id": 4,
             "generated_at": "2026-01-31",
             "positions": [
               { "drink_id": 7, "amount": 3 },
               { "drink_id": 9, "amount": 1 }
             ]
           }
         }' \
     https://kiosk.example.com/api/settlements
```

`201 Created` with the settlement (same shape as `GET`). The settlement starts
in state `draft`. Creation is atomic: if one position is invalid, nothing is
created and the response is `422`.

### `PATCH /api/settlements/:id`

Updates `client_id`, `monthly_report_id`, `generated_at` or `paid_at`. Positions
are managed through their own endpoints.

```bash
curl -X PATCH \
     -H "Authorization: Bearer $KIOSK_API_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"settlement": {"generated_at": "2026-02-28"}}' \
     https://kiosk.example.com/api/settlements/42
```

`200 OK` with the updated settlement.

Note: changing `generated_at` does **not** re-price existing positions — prices
are captured when a position is created. Delete and recreate positions if the
pricing date matters.

### `POST /api/settlements/:id/positions`

Adds a position. The price is derived from the drink price valid at the
settlement's `generated_at`.

```bash
curl -X POST \
     -H "Authorization: Bearer $KIOSK_API_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"position": {"drink_id": 7, "amount": 3}}' \
     https://kiosk.example.com/api/settlements/42/positions
```

```json
{
  "position": {
    "id": 91,
    "settlement_id": 42,
    "drink_id": 7,
    "drink_name": "Pils",
    "amount": 3,
    "price_in_cents": 360
  }
}
```

### `PATCH /api/settlements/:settlement_id/positions/:id`

Updates `drink_id` and/or `amount`. Note that updating does not re-derive the
price — set `amount` at creation time, or delete and recreate the position, when
the price must follow.

### `DELETE /api/settlements/:settlement_id/positions/:id`

`204 No Content`.

### `POST /api/settlements/:id/complete`

Moves the settlement from `draft` to `completed` and stamps `completed_at`.
Completed settlements are what the client's outstanding balance is computed
from.

```bash
curl -X POST -H "Authorization: Bearer $KIOSK_API_TOKEN" \
     https://kiosk.example.com/api/settlements/42/complete
```

`200 OK` with the settlement. Calling it on a settlement that is not `draft`
returns `422` / `invalid_transition`.

### `POST /api/settlements/:id/send_email`

Enqueues the settlement email to the client and stamps `email_sent_at`.
Delivery happens in the background (Solid Queue), so a `200` means "queued",
not "in the inbox".

```bash
curl -X POST -H "Authorization: Bearer $KIOSK_API_TOKEN" \
     https://kiosk.example.com/api/settlements/42/send_email
```

`200 OK` with the settlement (now carrying `email_sent_at`).

Returns `422` / `validation_failed` when

- the client has no email address (`"Client must have an email address"`), or
- the mail was already sent (`"Email sent at must be blank"`).

The second rule makes this endpoint safe against accidental double sends: a
retry never mails the client twice. Sending is possible in any state, but the
usual order is complete first, then send.

`email_first_opened_at` is filled in later, when the client opens the mail.

## The typical workflow

```bash
export KIOSK_API_TOKEN=…
export KIOSK_API=https://kiosk.example.com/api
AUTH="Authorization: Bearer $KIOSK_API_TOKEN"
JSON="Content-Type: application/json"

# 1. Who can be settled, and against which report?
curl -s -H "$AUTH" "$KIOSK_API/clients?active=true"
curl -s -H "$AUTH" "$KIOSK_API/monthly_reports"
curl -s -H "$AUTH" "$KIOSK_API/drinks"

# 2. Create the settlement including its positions
SETTLEMENT_ID=$(curl -s -X POST -H "$AUTH" -H "$JSON" \
  -d '{"settlement":{"client_id":1,"monthly_report_id":4,"generated_at":"2026-01-31",
       "positions":[{"drink_id":7,"amount":3}]}}' \
  "$KIOSK_API/settlements" | jq -r .settlement.id)

# 3. Correct it if needed
curl -s -X POST -H "$AUTH" -H "$JSON" \
  -d '{"position":{"drink_id":9,"amount":1}}' \
  "$KIOSK_API/settlements/$SETTLEMENT_ID/positions"

# 4. Complete it
curl -s -X POST -H "$AUTH" "$KIOSK_API/settlements/$SETTLEMENT_ID/complete"

# 5. Mail it to the client
curl -s -X POST -H "$AUTH" "$KIOSK_API/settlements/$SETTLEMENT_ID/send_email"
```

Payments are deliberately not part of this API — settle and mail here, book
payments in the web UI.

## Calling the API from this repo

`KioskApi::Client` (`lib/kiosk_api/client.rb`) is a dependency-free
(`net/http`) wrapper. It reads `API_TOKEN` and `KIOSK_API_URL` from the
environment, unwraps the top-level response key, and raises
`KioskApi::RequestError` (with `#status`, `#code`, `#body`) on any non-2xx.

```ruby
client = KioskApi::Client.new                      # or: .new(url:, token:)

client.clients(active: true)                       # => [ { "id" => 1, … }, … ]
client.drinks
client.monthly_reports
client.settlements(client_id: 1, state: "draft")
client.settlement(42)

settlement = client.create_settlement(
  client_id: 1, monthly_report_id: 4, generated_at: "2026-01-31",
  positions: [ { drink_id: 7, amount: 3 } ]
)

client.update_settlement(settlement["id"], generated_at: "2026-02-28")
client.add_position(settlement["id"], drink_id: 9, amount: 1)
client.update_position(settlement["id"], position_id, amount: 2)
client.delete_position(settlement["id"], position_id)
client.complete_settlement(settlement["id"])
client.send_settlement_email(settlement["id"])
```

It needs no Rails: `ruby -r./lib/kiosk_api -r./lib/kiosk_api/client -e …` works,
and inside `bin/rails console` it is autoloaded.

### `script/api`

The same thing as a CLI, printing pretty JSON. It loads `.env` itself, so it
works straight from a checkout:

```bash
script/api clients --active
script/api drinks
script/api monthly-reports
script/api settlements --client-id 1 --state draft
script/api settlement 42

script/api create-settlement --client-id 1 --monthly-report-id 4 \
                             --generated-at 2026-01-31 --positions 7:3,9:1
script/api update-settlement 42 --generated-at 2026-02-28
script/api add-position 42 --drink-id 9 --amount 1
script/api update-position 42 91 --amount 2
script/api delete-position 42 91
script/api complete 42
script/api send-email 42
```

`--positions` takes `DRINK_ID:AMOUNT` pairs separated by commas. Errors print
the API's message to stderr and exit non-zero, e.g.

```
422 invalid_transition: Event 'complete' cannot transition from 'completed'.
```

Run `script/api` without arguments for the full usage. To point it at a local
server: `KIOSK_API_URL=http://localhost:3050 script/api clients`.
