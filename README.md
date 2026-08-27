# ChatTakehome

A shared chat room built with Elixir, Phoenix LiveView, Ecto, and PostgreSQL.

## Prerequisites

- [Mise](https://mise.jdx.dev/) for the project toolchain and environment variables
- Podman and `podman-compose` for the local PostgreSQL service

## Development setup

`mise.toml` is the source of truth for the local Elixir version and development/test database environment. Before starting the application, update its `[env]` values if your local PostgreSQL credentials or database name differ:

```toml
[env]
DATABASE_USER = "..."
DATABASE_PASSWORD = "..."
DATABASE_NAME = "..."
```

Install the configured Elixir version once:

```sh
mise install
```

Then start the full development environment with one command:

```sh
mise run dev
```

This task starts PostgreSQL, fetches Elixir dependencies, creates and migrates the database, loads seed users, builds assets, and starts Phoenix. Visit [http://localhost:4000/home](http://localhost:4000/home) to see the user list and join the chat.

The development and test database name is `${DATABASE_NAME}_test`, which Phoenix creates automatically during setup.

## Tests

```sh
mise run test
```

## Seed data

Database setup adds four sample users: Ada Lovelace, Grace Hopper, Linus Torvalds, and Margaret Hamilton. They appear as offline until they join the shared chat room.

## Assumptions

- **The application has one shared chat room.** Multiple rooms are out of scope, so messages do not need a room
  association, users do not need room memberships, and queries do not need to filter by room. Adding rooms would
  also require per-room authorization and Presence topics.

- **Anonymous, browser-bound identity is sufficient.** When a visitor joins, the server creates a user and stores an
  opaque session token in the signed browser session. The token lets that browser re-enter as the same user without
  trusting a client-supplied user ID. Production would need account recovery, expiration and rotation, revocation,
  and protections for lost or stolen sessions.

- **A display name is a participant's public identity.** Names are trimmed and unique case-insensitively so two
  participants cannot appear under the same visible name. A visitor who loses their session cannot reclaim that name
  in this version of the application.

- **Online means connected to the shared chat room.** A visitor with a valid session is recognized by the application,
  but is offline while on the home page. Phoenix Presence derives online status from active chat-room connections and
  automatically removes a participant when their final connection is lost.

- **All participants have equal access.** Any recognized participant can read the shared room and see the registered
  user list and current online status. Roles, private rooms, and direct messages are out of scope.

- **Messages are durable and immutable for this scope.** The application persists a validated message before
  broadcasting it to connected clients. Message editing, deletion, retention, and audit policies are not included.

- **The server is authoritative.** The client provides message text, while the server resolves the author from the
  session token and validates the message. This prevents a client from choosing another user's ID when sending.

- **History must remain bounded as the room grows.** The room initially loads the newest 50 messages and fetches older
  messages with cursor pagination. A production deployment should add a composite index supporting the `(sent_at, id)`
  cursor order.

- **Abuse prevention and multi-node operations are out of scope.** This take-home does not include rate limiting,
  moderation, reporting, or spam controls. A production multi-node deployment would also require distributed
  PubSub/Presence configuration and operational monitoring.

## Architecture and Design

- **Phoenix LiveView** renders the home and chat interfaces and keeps them synchronized without a custom client-side application.
- **Users context** owns user creation, case-insensitive username uniqueness, and token-based lookup.
- **Chat context** owns message validation, persistence, author preloading, and cursor-based history pagination.
- **PostgreSQL/Ecto** persist users and messages. Messages reference their author and use server-generated timestamps.
- **Phoenix Presence** tracks active session tokens in the shared room. Presence is ephemeral by design, so disconnects automatically mark a user offline.
- **Phoenix PubSub** broadcasts a newly persisted message to connected chat clients. LiveView streams append messages efficiently while avoiding an ever-growing assign.
- **Router and UserAuth** separate public routes from the authenticated chat route. The session token is resolved on controller requests and LiveView mounts.

## User Flow

1. Visiting / redirects to /home.
2. /home lists every registered user with a realtime online or offline icon.
3. A new visitor selects Join Chat, enters an available display name, and submits the form.
4. The server creates a user, generates an opaque session token, stores that token in the browser session, and redirects the visitor to /chat. A name that is already in use is rejected case-insensitively.
5. The authenticated user joins the shared room. The chat displays recent history, the full user list with realtime status, and a message composer.
6. Leaving returns the visitor to /home; as long as the browser session remains, the token permits re-entry without creating another user.
