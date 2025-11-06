# Local Setup Runbook

This runbook provides step-by-step instructions for setting up the development environment.

## Prerequisites Check

Before starting, verify you have:

- [ ] Docker Engine 20.10+ installed
- [ ] Docker Compose 2.0+ installed
- [ ] Git installed
- [ ] Access to the repository

Check versions:

```bash
docker --version
docker compose version
git --version
```

## Initial Setup

### Step 1: Clone Repository

```bash
git clone https://github.com/FlowTech-Lab/Grenoble-Roller-Project.git
cd Grenoble-Roller-Project
```

### Step 2: Verify Credentials

Check if `config/master.key` exists:

```bash
ls -la config/master.key
```

If missing:
- Ask a team member for the key, OR
- Regenerate: `bin/rails credentials:edit`

See [Credentials Management](../../04-rails/setup/credentials.md) for details.

### Step 3: Start Docker Containers

```bash
docker compose -f ops/dev/docker-compose.yml up -d
```

Wait for containers to be healthy (check with `docker ps`).

### Step 4: Initialize Database

```bash
# Run migrations
docker exec grenoble-roller-dev bin/rails db:migrate

# Seed database
docker exec grenoble-roller-dev bin/rails db:seed
```

### Step 5: Verify Setup

1. Check application: http://localhost:3000
2. Check database connection:
   ```bash
   docker exec grenoble-roller-db-dev pg_isready -U postgres
   ```
3. Test login with default accounts (see main README)

## Common Operations

### View Logs

```bash
# Application logs
docker logs -f grenoble-roller-dev

# Database logs
docker logs -f grenoble-roller-db-dev
```

### Rails Console

```bash
docker exec -it grenoble-roller-dev bin/rails console
```

### Run Migrations

```bash
docker exec grenoble-roller-dev bin/rails db:migrate
```

### Reset Database

```bash
docker exec grenoble-roller-dev bin/rails db:reset
```

### Stop Containers

```bash
docker compose -f ops/dev/docker-compose.yml down
```

### Rebuild Containers

```bash
docker compose -f ops/dev/docker-compose.yml up -d --build
```

## Troubleshooting

### Container won't start

1. Check logs: `docker logs grenoble-roller-dev`
2. Check status: `docker ps -a`
3. Rebuild: `docker compose -f ops/dev/docker-compose.yml up -d --build`

### Database connection errors

1. Verify database is running: `docker ps | grep db`
2. Check database health: `docker exec grenoble-roller-db-dev pg_isready -U postgres`
3. Restart database: `docker compose -f ops/dev/docker-compose.yml restart db`

### Port conflicts

If ports 3000 or 5434 are in use:

1. Find process: `lsof -i :3000` or `lsof -i :5434`
2. Stop conflicting service, OR
3. Modify ports in `ops/dev/docker-compose.yml`

### Credentials errors

If you see "Missing 'config/master.key'":

1. Verify file exists: `ls config/master.key`
2. If missing, see [Credentials Management](../../04-rails/setup/credentials.md)

## Next Steps

After successful setup:

1. Read [Domain Models](../../03-architecture/domain/models.md)
2. Review [Rails Conventions](../../04-rails/conventions/)
3. Check [Testing Strategy](../../05-testing/)

## Related Documentation

- [Local Development Setup](../../04-rails/setup/local-development.md) - Detailed setup guide
- [Credentials Management](../../04-rails/setup/credentials.md) - Secrets handling
- [Domain Models](../../03-architecture/domain/models.md) - Data structure

