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
