# Setup Scripts

This directory contains setup scripts to help you get started with the Grenoble Roller project on a new machine.

## Available Scripts

### `setup.sh`

General setup script that checks prerequisites and installs dependencies locally (not using Docker).

**Usage:**
```bash
./script/setup.sh
```

**Features:**
- Checks for required tools (Docker, Git, Ruby, Node.js, npm)
- Verifies credentials (config/master.key)
- Installs Node.js dependencies (`npm install`)
- Installs Ruby gems (`bundle install`)
- Provides next steps instructions

**Options:**
- `--docker-only`: Skip local dependency installation (for Docker-only setups)

### `setup-docker.sh`

Automated Docker setup script (recommended for most users).

**Usage:**
```bash
./script/setup-docker.sh
```

**Features:**
- Interactive setup for development or staging
- Automatically builds and starts Docker containers
- Runs database migrations
- Optionally seeds the database
- Checks for staging branch (for staging environment)

**What it does:**
1. Checks Docker and Docker Compose availability
2. Prompts for environment (development or staging)
3. For staging: checks/switches to staging branch
4. Builds and starts containers
5. Runs migrations
6. Optionally seeds database
7. Provides useful commands

## Quick Start

### Development

```bash
git clone https://github.com/FlowTech-Lab/Grenoble-Roller-Project.git
cd Grenoble-Roller-Project
./script/setup-docker.sh
# Select option 1 (Development)
```

### Staging

```bash
git clone https://github.com/FlowTech-Lab/Grenoble-Roller-Project.git
cd Grenoble-Roller-Project
./script/setup-docker.sh
# Select option 2 (Staging)
```

## Troubleshooting

### Scripts are not executable

```bash
chmod +x script/setup.sh
chmod +x script/setup-docker.sh
```

### Docker not found

Install Docker and Docker Compose:
- Linux: Follow [Docker installation guide](https://docs.docker.com/engine/install/)
- macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
- Windows: Install [Docker Desktop](https://www.docker.com/products/docker-desktop)

### Credentials error

If you see errors about `config/master.key`:
1. Ask a team member for the master key, OR
2. Generate new credentials: `bin/rails credentials:edit`

## Related Documentation

- [Local Development Setup](../docs/04-rails/setup/local-development.md)
- [Staging Setup](../docs/07-ops/runbooks/staging-setup.md)
- [Main README](../README.md)

