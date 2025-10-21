# 🐳 Docker Setup - Grenoble Roller UI Kit

## Quick Start

Launch the UI Kit with Docker in 2 commands:

```bash
cd UI-Kit
docker-compose up -d
```

## Access

- **URL**: http://localhost:3082
- **Port**: 3082 (external) → 80 (internal nginx)

## Commands

### Start
```bash
docker-compose up -d
```

### Stop
```bash
docker-compose down
```

### View logs
```bash
docker-compose logs -f
```

### Restart
```bash
docker-compose restart
```

## What's Running?

- **Service**: `grenoble-roller-ui-kit`
- **Container**: nginx:alpine
- **Volume**: Current directory mounted as read-only
- **Network**: `grenoble-roller-network`

## For Clients

Share this URL with your clients to showcase the UI Kit:
```
http://localhost:3082
```

Or expose via ngrok for remote access:
```bash
ngrok http 3082
```

---

**Note**: The container runs nginx in read-only mode for security.

