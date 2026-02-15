# My Local Project (Hundong2)

> **⚠️ SECURITY WARNING**
> This project contains setup instructions for sensitive services (Keycloak, Nginx Proxy Manager, Database).
> *   **Credentials**: The default passwords (e.g., `admin`/`admin`, `password`) in `docker-compose.yml` and documentation MUST be changed immediately in a production environment.
> *   **Secrets**: Never commit `.env` files or hardcoded secrets (like `KEYCLOAK_ADMIN_PASSWORD`, Google Client Secrets) to a public repository. Use environment variables.
> *   **Data Persistence**: The `data/` and `letsencrypt/` directories contain persistent data (database files, SSL certificates). These are excluded from git via `.gitignore` to prevent leaks. **Back them up securely.**

## Revival Plan & Status
This project implements a scalable web service architecture featuring SSO with Keycloak, Nginx Proxy Manager (NPM), and a FastAPI backend with monitoring tools.

## Stack Overview
- **Reverse Proxy**: Nginx Proxy Manager (NPM)
- **Authentication**: Keycloak (Google OAuth)
- **Backend**: FastAPI
- **Database**: PostgreSQL
- **Caching**: Redis
- **Monitoring**: Grafana

## Prerequisites
- Docker & Docker Compose installed.
- Domain `hundong2.xyz` pointing to this server.
- Google Cloud Console Project with OAuth Credentials.

## Quick Start

1. **Clone & Setup**:
   Ensure you are in the project root.

2. **Start Services**:
   ```bash
   docker-compose up -d
   ```

3. **Verify Status**:
   ```bash
   docker-compose ps
   ```

## Configuration Guide

### 1. Nginx Proxy Manager (NPM)
- Access: `http://localhost:81` or `http://hundong2.xyz:81`
- Default Creds: `admin@example.com` / `changeme`
- **Action**: Login and change credentials immediately.
- **Proxy Hosts**:
    - `auth.hundong2.xyz` -> `http://keycloak:8080`
    - `api.hundong2.xyz` -> `http://backend:8000`
    - `grafana.hundong2.xyz` -> `http://grafana:3000`

### 2. Keycloak Setup
- Access: `http://localhost:8080` (or via NPM proxy)
- Admin Console: `admin` / `admin` (set in docker-compose.yml)
- **Create Realm**: `hundong`
- **Configure Google Identity Provider**:
    - Go to Identity Providers -> Google.
    - Enter Client ID and Secret.
- **Create Client**: `fastapi`
    - Valid Redirect URIs: `http://localhost:8000/*` (adjust for prod)

### 3. FastAPI Backend
- Access: `http://localhost:8000`
- Docs: `http://localhost:8000/docs`

## Development
- Backend code is in `./backend`.
- Rebuild backend after changes:
  ```bash
  docker-compose build backend && docker-compose up -d backend
  ```
