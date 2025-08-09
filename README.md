# Multi-Service Docker Architecture with Keycloak Authentication

## 개요

이 프로젝트는 Docker 기반의 통합 서버 아키텍처로, Keycloak 인증을 통해 보호되는 여러 서비스를 단일 도메인으로 제공합니다.

## 아키텍처 설계

### 전체 구조
```
┌─────────────────────────────────────────────────────────────┐
│                    Internet/Domain                          │
└─────────────────────┬───────────────────────────────────────┘
                      │ HTTPS (443) / HTTP (80)
┌─────────────────────▼───────────────────────────────────────┐
│                   Nginx (Reverse Proxy)                    │
│                  + SSL Termination                         │
│                  + Keycloak Integration                    │
└─────────┬───────────┬───────────┬───────────┬───────────────┘
          │           │           │           │
          ▼           ▼           ▼           ▼
    ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────┐
    │Keycloak │ │OpenWebUI│ │Code     │ │FastAPI      │
    │Auth     │ │(/webui) │ │Server   │ │Toy Server   │
    │Server   │ │         │ │(/vscode)│ │(/toy)       │
    └─────────┘ └─────────┘ └─────────┘ └─────────────┘
```

### 주요 구성요소

1. **Nginx (리버스 프록시)**
   - SSL/TLS 종료점
   - 단일 진입점을 통한 라우팅
   - Keycloak 인증 통합
   - 정적 파일 서빙

2. **Keycloak (인증 서버)**
   - OAuth 2.0/OpenID Connect 기반 인증
   - 사용자 관리 및 권한 제어
   - 모든 서비스에 대한 통합 인증

3. **OpenWebUI (/webui)**
   - AI 모델 실험 환경
   - LLM 인터페이스
   - Keycloak 인증 보호

4. **Code Server (/vscode)**
   - 웹 기반 VSCode 환경
   - 원격 개발 환경
   - Keycloak 인증 보호

5. **FastAPI 서버 (/toy)**
   - 간단한 API 서버
   - 실험 및 테스트용
   - Keycloak 인증 보호

## 보안 설계

### 인증 플로우
1. 사용자가 서비스에 접근
2. Nginx가 Keycloak으로 인증 확인
3. 미인증시 Keycloak 로그인 페이지로 리다이렉트
4. 인증 성공시 요청된 서비스로 프록시

### 네트워크 보안
- 외부 노출: Nginx만 80/443 포트
- 내부 통신: Docker 내부 네트워크 사용
- 서비스간 격리된 네트워크 세그먼트

## 시스템 요구사항

- Docker Engine 20.10+
- Docker Compose 2.0+
- 최소 4GB RAM
- 도메인 또는 SSL 인증서 (선택사항)

## 설치 및 실행

### 사전 요구사항
- Docker Engine 20.10+
- Docker Compose 2.0+
- 최소 4GB RAM
- 사용 가능한 도메인 (선택사항, SSL 사용시)

### 1. 프로젝트 다운로드
```bash
git clone <repository-url>
cd <project-directory>
```

### 2. 환경 변수 설정
```bash
# .env 파일 편집 (기본값이 설정되어 있음)
vim .env

# 주요 설정 항목:
# - DOMAIN: 도메인 명 (기본: localhost)
# - KEYCLOAK_ADMIN_PASSWORD: Keycloak 관리자 비밀번호
# - CODE_SERVER_PASSWORD: VSCode Server 접속 비밀번호
# - 모든 SECRET_KEY 값들을 보안을 위해 변경
```

### 3. SSL 인증서 설정 (선택사항)
```bash
# 자동 SSL 설정 스크립트 사용
./scripts/setup-ssl.sh your-domain.com

# 또는 수동 설정:
# 1) Let's Encrypt 사용
# 2) 자체 서명 인증서 생성
# 3) 기존 인증서 사용
```

### 4. 서비스 시작
```bash
# Docker 시작 (필요시)
sudo systemctl start docker

# 전체 서비스 빌드 및 시작
docker compose up -d --build

# 서비스 상태 확인
docker-compose ps

# 로그 실시간 모니터링
docker-compose logs -f
```

### 5. Keycloak 초기 설정
```bash
# Keycloak 초기화 스크립트 실행 (선택사항)
./scripts/init-keycloak.sh

# 또는 수동 설정:
# 1. http://localhost/auth/admin 접속
# 2. 관리자 로그인 (admin/admin123)
# 3. Services Realm이 자동으로 생성됨
```

### 6. 동작 확인
```bash
# 헬스 체크
curl http://localhost:26280/health

# Keycloak 상태 확인
curl http://localhost:26280/auth/realms/services/.well-known/openid_configuration

# 각 서비스 접속 테스트
# - Keycloak 관리: http://localhost:26280/auth/admin
# - OpenWebUI: http://localhost:26280/webui (testuser/testpassword)
# - VSCode: http://localhost:26280/vscode (testuser/testpassword)
# - FastAPI: http://localhost:26280/toy (testuser/testpassword)

# Hugging Face 모델 다운로드/스트리밍 (인증 필요)
curl -H "Authorization: Bearer <token>" "http://localhost:26280/toy/hf/models/download?model_id=bert-base-uncased"
curl -H "Authorization: Bearer <token>" "http://localhost:26280/toy/hf/files/stream?relative_path=models--bert-base-uncased/snapshots/<hash>/config.json" -OJ
```

## 서비스 접근

- **Keycloak 관리**: http://localhost:26280/auth/admin (HTTPS: https://your-domain:26443/auth/admin)
- **OpenWebUI**: http://localhost:26280/webui (HTTPS: https://your-domain:26443/webui)
- **VSCode Server**: http://localhost:26280/vscode (HTTPS: https://your-domain:26443/vscode)
- **FastAPI 서버**: http://localhost:26280/toy (HTTPS: https://your-domain:26443/toy)

## Nginx 라우팅/프록시 설정 요약

- **포트 보존**: Keycloak 리다이렉트에서 포트가 누락되지 않도록 `Host`, `X-Forwarded-*` 헤더를 `$http_host`로 전달하고 `proxy_redirect off` 설정.
- **서브패스 운영**: `/webui`, `/vscode`, `/toy`는 프록시 앞단에서 prefix를 제거하여 백엔드가 루트 경로로 실행되도록 구성.
- **OpenWebUI**: `WEBUI_BASE_URL=/webui`, `PUBLIC_URL=/webui` 환경변수로 서브패스 자산 경로 정합성 유지.

## Keycloak 설정 주의사항

- Docker 내부 접근 URL: `http://keycloak:8080`
- 외부에서 접근: `http://localhost:26280/auth`
- 컨테이너 환경변수: `KC_HTTP_RELATIVE_PATH=/auth`, `KC_PROXY=edge`, `KC_PROXY_ADDRESS_FORWARDING=true`

## Hugging Face 캐시 설계

- 공용 캐시: `${HF_HOME:-~/.cache/huggingface}`를 Nginx 뒤 서비스들과 공유 마운트.
- FastAPI에서 `/toy/hf/models/download`로 서버측 snapshot 다운로드 트리거.
- `/toy/hf/files/stream`로 파일 스트리밍 제공.

## 운영/테스트 절차

1) 빌드/실행: `docker compose up -d --build`
2) 준비 대기: Keycloak 기동에 2~3분 소요. `docker compose logs -f keycloak`
3) 헬스체크: `/health`, `/toy/health`
4) Keycloak OpenID 설정: `/auth/realms/<realm>/.well-known/openid_configuration`
5) 라우팅 확인: `/auth`, `/webui`, `/vscode`, `/toy`

## DNS/SSH/SSL 확장 설계

- DNS: `A` 레코드로 Nginx 호스트 매핑. `.env`의 `DOMAIN` 반영.
- SSL: `nginx/conf.d/ssl.conf` 활성화 후 443:26443 매핑 유지. Let's Encrypt 자동화 스크립트 제공 예정 (`scripts/setup-ssl.sh`).
- 프록시 보안 헤더: HSTS, CSP는 SSL 활성화 후 적용.
- SSH: 호스트 OS 표준 `sshd` 사용. 방화벽 22 포트 허용. 키 인증 권장.

## 트러블슈팅 핵심

- 포트 누락 리다이렉트: Keycloak 클라이언트 `Base URL`을 `http://localhost:26280`로, `Valid redirect URIs`에 `http://localhost:26280/*` 포함.
- 502/404 시 각 서비스 로그/내부 wget으로 백엔드 연결 확인. `TROUBLESHOOTING.md` 참고.

## 기여 가이드와 작업 순서 (토큰 절약)

1. `docker-compose.yml`과 `nginx/conf.d/default.conf`를 우선 열람
2. 라우팅 이슈는 Nginx 헤더/리라이트 우선 점검
3. OpenWebUI 서브패스는 환경변수 `WEBUI_BASE_URL` 확인
4. FastAPI 추가 엔드포인트는 `/toy/*` 아래에 구현
5. 성공 기준: `/auth`, `/webui`, `/vscode`, `/toy` 모두 200/동작

## 운영 및 모니터링

### 로그 확인
```bash
# 전체 서비스 로그
docker-compose logs

# 특정 서비스 로그
docker-compose logs nginx
docker-compose logs keycloak
```

### 서비스 상태 확인
```bash
# 실행중인 컨테이너 확인
docker-compose ps

# 서비스 재시작
docker-compose restart [service-name]
```

### 백업
```bash
# Keycloak 데이터베이스 백업
./scripts/backup-keycloak.sh

# 전체 볼륨 백업
./scripts/backup-volumes.sh
```

## 트러블슈팅

### 일반적인 문제

1. **서비스 접근 불가**
   - Nginx 설정 확인
   - 포트 충돌 확인
   - 방화벽 설정 확인

2. **인증 오류**
   - Keycloak 설정 확인
   - 클라이언트 설정 확인
   - 토큰 만료 확인

3. **SSL 인증서 오류**
   - 인증서 파일 경로 확인
   - 인증서 유효성 확인
   - 도메인 일치성 확인

## 개발 및 커스터마이징

### 새 서비스 추가
1. docker-compose.yml에 서비스 추가
2. nginx/conf.d/에 설정 파일 추가
3. Keycloak에 새 클라이언트 등록

### 설정 파일 위치
- Nginx: `nginx/conf.d/`
- Keycloak: `keycloak/`
- 환경변수: `.env`

## 라이센스

MIT License

---

## 업데이트 로그

### 2025-08-08
- 초기 프로젝트 구조 생성
- README.md 작성 시작

## 사용 예제

### FastAPI 서비스 API 호출
```bash
# 공개 엔드포인트
curl http://localhost:26280/toy/
curl http://localhost:26280/toy/health

# 로그인 후 토큰 획득 (테스트용)
TOKEN=$(curl -s -X POST "http://localhost:26280/auth/realms/services/protocol/openid_connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=fastapi" \
  -d "client_secret=fastapi-secret" \
  -d "username=testuser" \
  -d "password=testpassword" | \
  jq -r '.access_token')

# 보호된 엔드포인트 호출
curl -H "Authorization: Bearer $TOKEN" http://localhost:26280/toy/protected
curl -H "Authorization: Bearer $TOKEN" http://localhost:26280/toy/user/profile
curl -H "Authorization: Bearer $TOKEN" http://localhost:26280/toy/data
```

### OpenWebUI 사용
1. http://localhost:26280/webui 접속
2. testuser/testpassword로 로그인
3. AI 모델 설정 및 실험 실행

### VSCode Server 사용
1. http://localhost:26280/vscode 접속
2. testuser/testpassword로 로그인
3. /home/coder/workspace 디렉토리에서 개발 작업

## 보안 고려사항

### 운영 환경을 위한 모범 사례

1. **비밀번호 변경**
   - 모든 기본 비밀번호 변경 필수
   - 강력한 비밀번호 사용 (16자 이상, 특수문자 포함)
   - 주기적 비밀번호 교체

2. **SSL/TLS 설정**
   - 운영 환경에서는 반드시 SSL 사용
   - Let's Encrypt 또는 유료 인증서 사용
   - HSTS 헤더 활성화

3. **방화벽 설정**
   - 80, 443 포트만 외부 노출
   - 내부 서비스 간 통신 방화벽 규칙 설정
   - DDoS 보호 설정

### 데이터 보호
- 정기 백업 실시
- 데이터베이스 암호화
- 중요 데이터 오프사이트 백업
