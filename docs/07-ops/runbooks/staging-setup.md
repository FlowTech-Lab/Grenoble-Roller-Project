# Staging Environment Setup

This guide explains how to set up and deploy the Grenoble Roller application in the staging environment.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Access to the repository: [https://github.com/FlowTech-Lab/Grenoble-Roller-Project](https://github.com/FlowTech-Lab/Grenoble-Roller-Project)
- Environment variables configured (`.env` file)

## Overview

The staging environment is a production-like environment used for:
- Testing features before production deployment
- User acceptance testing (UAT)
- Performance testing
- Integration testing

**Configuration:**
- Port: `3001` (mapped to container port 3000)
- Database: `grenoble_roller_production` (PostgreSQL)
- Environment: `production` (Rails)
- Container: `grenoble-roller-staging`

## Initial Setup

### 1. Clone the Repository

If you haven't cloned the repository yet:

```bash
git clone https://github.com/FlowTech-Lab/Grenoble-Roller-Project.git
cd Grenoble-Roller-Project
```

### 2. Checkout Staging Branch

```bash
# Ensure you're on the staging branch
git checkout staging

# Pull latest changes
git pull origin staging
```

**Note**: If the staging branch doesn't exist yet, create it:
```bash
git checkout -b staging
git push -u origin staging
```

### 3. Prepare Environment Variables

Create a `.env` file in the project root directory with the following variables:

```bash
# Database
DATABASE_URL=postgresql://postgres:postgres@db:5432/grenoble_roller_production
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=grenoble_roller_production

# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=<your-master-key-here>

# Optional: Add other environment variables as needed
# SMTP settings, API keys, etc.
```

**Important**: 
- Replace `<your-master-key-here>` with the actual master key from `config/master.key`
- Never commit the `.env` file (it's in `.gitignore`)
- Use secure passwords in production-like environments

### 4. Build and Start Containers

```bash
# Build and start staging containers
docker compose -f ops/staging/docker-compose.yml up -d --build
```

This will:
- Build the Rails application image
- Start PostgreSQL database
- Start the Rails application
- Create Docker volumes for data persistence

### 5. Wait for Services to be Healthy

Check container status:

```bash
docker ps | grep staging
```

Wait for health checks to pass (containers should show "healthy" status).

### 6. Initialize Database

```bash
# Run migrations
docker exec grenoble-roller-staging bin/rails db:migrate

# Seed database (optional - only if you need test data)
docker exec grenoble-roller-staging bin/rails db:seed
```

**Note**: In staging, you may want to seed with production-like data instead of test data.

### 7. Verify Setup

1. **Check application**: http://localhost:3001
2. **Check database connection**:
   ```bash
   docker exec grenoble-roller-db-staging pg_isready -U postgres
   ```
3. **Check application logs**:
   ```bash
   docker logs grenoble-roller-staging
   ```

## Accessing the Application

- **Application URL**: http://localhost:3001
- **Database**: localhost:5434 (if exposed, check docker-compose.yml)
  - User: `postgres`
  - Password: `postgres`
  - Database: `grenoble_roller_production`

## Common Operations

### View Logs

```bash
# Application logs
docker logs -f grenoble-roller-staging

# Database logs
docker logs -f grenoble-roller-db-staging
```

### Rails Console

```bash
docker exec -it grenoble-roller-staging bin/rails console
```

### Run Migrations

```bash
docker exec grenoble-roller-staging bin/rails db:migrate
```

### Run Seeds (if needed)

```bash
docker exec grenoble-roller-staging bin/rails db:seed
```

### Reset Database

```bash
# Drop, create, migrate, and seed
docker exec grenoble-roller-staging bin/rails db:reset
```

### Stop Containers

```bash
docker compose -f ops/staging/docker-compose.yml down
```

### Stop and Remove Volumes (⚠️ Deletes Data)

```bash
docker compose -f ops/staging/docker-compose.yml down -v
```

### Rebuild Containers

```bash
docker compose -f ops/staging/docker-compose.yml up -d --build
```

## Database Management

### Backup Database

```bash
# Create backup
docker exec grenoble-roller-db-staging pg_dump -U postgres grenoble_roller_production > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Database

```bash
# Restore from backup
cat backup_YYYYMMDD_HHMMSS.sql | docker exec -i grenoble-roller-db-staging psql -U postgres grenoble_roller_production
```

### Access Database Directly

```bash
docker exec -it grenoble-roller-db-staging psql -U postgres grenoble_roller_production
```

## Updating the Application

### Update Code

```bash
# Switch to staging branch
git checkout staging

# Pull latest changes from staging branch
git pull origin staging

# Rebuild and restart
docker compose -f ops/staging/docker-compose.yml up -d --build
```

### Run Migrations After Update

```bash
docker exec grenoble-roller-staging bin/rails db:migrate
```

### Restart Application

```bash
docker compose -f ops/staging/docker-compose.yml restart web
```

## Troubleshooting

### Container won't start

```bash
# Check container status
docker ps -a | grep staging

# View container logs
docker logs grenoble-roller-staging

# Check environment variables
docker exec grenoble-roller-staging env | grep RAILS

# Rebuild containers
docker compose -f ops/staging/docker-compose.yml up -d --build
```

### Database connection errors

```bash
# Check if database is running
docker ps | grep grenoble-roller-db-staging

# Check database health
docker exec grenoble-roller-db-staging pg_isready -U postgres

# Restart database
docker compose -f ops/staging/docker-compose.yml restart db

# Check database logs
docker logs grenoble-roller-db-staging
```

### Credentials errors

If you see "Missing 'config/master.key' to decrypt credentials":

1. Verify `RAILS_MASTER_KEY` is set in `.env` file
2. Check environment variable is loaded:
   ```bash
   docker exec grenoble-roller-staging env | grep RAILS_MASTER_KEY
   ```
3. Ensure `.env` file is in the project root
4. Restart containers after updating `.env`

### Port already in use

If port 3001 is already in use:

1. Find the process using the port:
   ```bash
   lsof -i :3001
   ```
2. Stop the conflicting service, OR
3. Modify the port in `ops/staging/docker-compose.yml`:
   ```yaml
   ports:
     - "3001:3000"  # Change 3001 to another port
   ```

### Application errors

```bash
# Check application logs
docker logs -f grenoble-roller-staging

# Check Rails environment
docker exec grenoble-roller-staging bin/rails runner "puts Rails.env"

# Check database connection
docker exec grenoble-roller-staging bin/rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').first"
```

## Data Persistence

The staging environment uses Docker volumes for data persistence:

- `grenoble-roller-staging-data`: Application data
- `grenoble-roller-staging-db-data`: Database data

**Location**: Managed by Docker (usually in `/var/lib/docker/volumes/`)

**Backup**: Use the database backup commands above to backup data.

## Security Considerations

### Staging Environment

- Use strong passwords for database
- Keep `.env` file secure and never commit it
- Rotate `RAILS_MASTER_KEY` regularly
- Use HTTPS in production-like environments
- Restrict access to staging environment

### Credentials Management

- Store `RAILS_MASTER_KEY` securely
- Use environment variables for sensitive data
- Never log credentials
- Rotate credentials regularly

## Monitoring

### Health Checks

The staging environment includes health checks:

```bash
# Check container health
docker ps | grep staging

# Manual health check
curl -f http://localhost:3001/up
```

### Application Metrics

Monitor application performance:

```bash
# View resource usage
docker stats grenoble-roller-staging

# Check application response time
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:3001
```

## Differences from Development

| Aspect | Development | Staging |
|--------|-------------|---------|
| Port | 3000 | 3001 |
| Environment | development | production |
| Database | grenoble_roller_development | grenoble_roller_production |
| Hot reload | Yes | No |
| Asset compilation | On demand | Precompiled |
| Logging | Verbose | Production-like |
| Error pages | Detailed | User-friendly |

## Next Steps

After staging is set up:

1. Verify all features work correctly
2. Run performance tests
3. Conduct user acceptance testing
4. Review logs for errors
5. Prepare for production deployment

## Related Documentation

- [Local Development Setup](../04-rails/setup/local-development.md) - Development environment
- [Production Setup](production-setup.md) - Production deployment (if exists)
- [Credentials Management](../04-rails/setup/credentials.md) - Secrets handling

