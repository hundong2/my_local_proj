# Project Roadmap & Migration Plan

이 문서는 현재 프로젝트의 진행 상황과 향후 개선/마이그레이션 계획을 관리합니다.

## ✅ Completed Tasks
- [x] Project Initialization & Docker Compose Setup
- [x] Keycloak Setup (Identity Provider)
- [x] Nginx Proxy Manager (NPM) Setup
- [x] FastAPI Backend Development (with Auth Integration)
- [x] Grafana Integration
- [x] Localhost Testing Environment Configuration
- [x] Documentation (`walkthrough.md`, `SSO.md`)
- [x] Security Review (`.gitignore`, `README.md` warnings)

## 🚀 Ongoing / Upcoming Tasks
- [ ] **Frontend Integration**:
    - [ ] Create a simple frontend (React/Vue/HTML) to demonstrate actual SSO redirection flow.
    - [ ] Implement logout functionality.
- [ ] **HTTPS / SSL Setup**:
    - [ ] Configure Let's Encrypt in NPM for `hundong2.xyz` domain (when DNS is ready).
    - [ ] Switch all services to HTTPS.
- [ ] **Production Hardening**:
    - [ ] Change default passwords (Keycloak, DB, NPM).
    - [ ] Move secrets to `.env` file.

## 🔄 Future Migration Plans (Optimization)
만약 Keycloak이 현재 프로젝트 규모에 비해 너무 무겁거나(Resource Heavy), 유지보수가 어렵다고 판단될 경우 고려할 작업입니다.

### [TODO] Migrate to Lightweight Identity Provider
- [ ] **Alternative Selection**:
    - [ ] **Candidate 1: Authentik** (Recommended for modernity & ease of use)
    - [ ] Candidate 2: Authelia (Best for simple proxy protection)
- [ ] **Migration Steps**:
    1.  [ ] Deploy Authentik container via Docker Compose.
    2.  [ ] Re-implement Google SSO connection in Authentik.
    3.  [ ] Update Backend (`auth.py`): Change OIDC Discovery URL.
    4.  [ ] Update NPM: Point authentication middleware to Authentik.
    5.  [ ] Verify user login flow and token validation.
