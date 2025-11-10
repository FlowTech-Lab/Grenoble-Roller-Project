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

### Step 4: Install Dependencies and Initialize Database

```bash
# Install gems (required for first setup)
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle install

# Run migrations
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails db:migrate

# Seed database
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails db:seed
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
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails console
```

### Run Migrations

```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails db:migrate
```

### Reset Database

```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails db:reset
```

### Run Tests

```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec
```

### Stop Containers

```bash
docker compose -f ops/dev/docker-compose.yml down
```

### Rebuild Containers

```bash
# Quick rebuild (with cache)
docker compose -f ops/dev/docker-compose.yml up -d --build
```

### Clean Rebuild (Fresh Start)

For a complete clean rebuild from scratch:

```bash
# Stop and remove all containers and volumes
docker compose -f ops/dev/docker-compose.yml down --volumes

# Rebuild containers (no cache)
docker compose -f ops/dev/docker-compose.yml build --no-cache web

# Start database
docker compose -f ops/dev/docker-compose.yml up -d db

# Install gems
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle install

# Setup database (create, migrate, seed)
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec rails db:setup

# Setup test database
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bash -lc "bundle exec rails db:drop db:create db:schema:load"

# Restore Bootstrap assets (if needed)
cp node_modules/bootstrap/dist/js/bootstrap.bundle.min.js vendor/javascript/bootstrap.bundle.min.js
mkdir -p app/assets/builds/fonts
cp node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff2 app/assets/builds/fonts/bootstrap-icons.woff2
cp node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff app/assets/builds/fonts/bootstrap-icons.woff
npm run build:css

# Start application
docker compose -f ops/dev/docker-compose.yml up web
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

