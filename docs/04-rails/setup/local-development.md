# Local Development Setup

This guide explains how to set up the Grenoble Roller project for local development using Docker.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

## Quick Start

### Option 1: Automated Setup (Recommended)

After cloning the repository, you can use the automated setup script:

```bash
git clone https://github.com/FlowTech-Lab/Grenoble-Roller-Project.git
cd Grenoble-Roller-Project
./script/setup-docker.sh
```

This script will:
- Check prerequisites (Docker, Docker Compose, etc.)
- Build and start containers
- Run database migrations
- Optionally seed the database

### Option 2: Manual Setup

### 1. Clone the Repository

```bash
git clone https://github.com/FlowTech-Lab/Grenoble-Roller-Project.git
cd Grenoble-Roller-Project
```

### 2. Configure Credentials

The project uses Rails encrypted credentials. If you don't have `config/master.key`:

```bash
# This will create a new master.key and credentials.yml.enc
bin/rails credentials:edit
```

**Note**: If you're working in a team, ask for the `master.key` file (it's not in git for security reasons).

### 3. Start Docker Containers

```bash
docker compose -f ops/dev/docker-compose.yml up -d
```

This will:
- Build the Rails application container
- Start PostgreSQL database
- Expose the app on http://localhost:3000
- Expose the database on localhost:5434

### 4. Initialize Database

```bash
# Run migrations
docker exec grenoble-roller-dev bin/rails db:migrate

# Seed the database with test data
docker exec grenoble-roller-dev bin/rails db:seed
```

### 5. Access the Application

- **Application**: http://localhost:3000
- **Database**: localhost:5434
  - User: `postgres`
  - Password: `postgres`
  - Database: `grenoble_roller_development`

## Default Test Accounts

After running `db:seed`, you can log in with:

- **Super Admin**: `T3rorX@hotmail.fr` / `T3rorX123`
- **Admin**: `admin@roller.com` / `admin123`
- **Test Users**: `client1@example.com` to `client5@example.com` / `password123`

## Development Workflow

### View Logs

```bash
# Application logs
docker logs -f grenoble-roller-dev

# Database logs
docker logs -f grenoble-roller-db-dev
```

### Run Rails Commands

```bash
# Rails console
docker exec -it grenoble-roller-dev bin/rails console

# Run migrations
docker exec grenoble-roller-dev bin/rails db:migrate

# Run tests
docker exec grenoble-roller-dev bin/rails test

# Generate a new model/controller
docker exec grenoble-roller-dev bin/rails generate model Product name:string
```

### Stop Containers

```bash
docker compose -f ops/dev/docker-compose.yml down
```

### Reset Database

```bash
# Drop, create, migrate, and seed
docker exec grenoble-roller-dev bin/rails db:reset
```

## Docker Compose Configuration

The development environment is configured in `ops/dev/docker-compose.yml`:

- **Web container**: `grenoble-roller-dev` (port 3000)
- **Database container**: `grenoble-roller-db-dev` (port 5434)
- **Volumes**: Code is mounted for hot-reload
- **Health checks**: Automatic container health monitoring

## Troubleshooting

### Container won't start

```bash
# Check container status
docker ps -a

# View container logs
docker logs grenoble-roller-dev

# Rebuild containers
docker compose -f ops/dev/docker-compose.yml up -d --build
```

### Database connection errors

```bash
# Check if database is healthy
docker exec grenoble-roller-db-dev pg_isready -U postgres

# Restart database
docker compose -f ops/dev/docker-compose.yml restart db
```

### Credentials errors

If you see "Missing 'config/master.key' to decrypt credentials":

1. Check if `config/master.key` exists
2. If not, regenerate: `bin/rails credentials:edit`
3. Or ask a team member for the key

### Port already in use

If port 3000 or 5434 is already in use:

1. Stop the conflicting service
2. Or modify ports in `ops/dev/docker-compose.yml`

## Next Steps

- Read the [Rails conventions](conventions/)
- Check the [architecture documentation](../03-architecture/)
- Review the [testing strategy](../05-testing/)

