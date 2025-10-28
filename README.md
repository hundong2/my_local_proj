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

### 스모크 테스트 실행

간단 검증 스크립트:

```bash
chmod +x scripts/smoke-test.sh
./scripts/smoke-test.sh
```

환경변수로 베이스 URL을 바꾸려면:

```bash
BASE_URL=https://your-domain ./scripts/smoke-test.sh
```

예시 환경 설정은 `.env.example`를 참고해 `.env`를 생성하세요.

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

## TODO: 인증 보호(SSO), SSL 활성화, 도메인 적용 가이드

아래 순서를 그대로 따라 하면, 다른 모델/사람도 중간부터 이어서 진행할 수 있도록 단계별로 정리되어 있습니다.

### 1) 인증 보호(SSO) 적용 – oauth2-proxy + Keycloak

- 목적: `/webui`, `/vscode`, `/toy` 경로에 Keycloak 기반 SSO 보호 적용
- 방식: Nginx `auth_request` + `oauth2-proxy`(Keycloak OIDC Provider)

절차
1. Keycloak에 클라이언트 생성
   - Realm: 원하는 Realm (예: `master` 또는 `services`)
   - Client ID: `nginx-oauth2-proxy`
   - Access Type: `confidential`
   - Valid Redirect URIs: `http(s)://<DOMAIN>/oauth2/callback`
   - Web Origins: `http(s)://<DOMAIN>`
   - Client Secret 복사(아래 환경변수에 사용)

2. docker-compose에 `oauth2-proxy` 서비스 추가 (예시 설정)
   - 편집 파일: `docker-compose.yml`
   - 추가 블록(예시):
     ```yaml
     oauth2-proxy:
       image: quay.io/oauth2-proxy/oauth2-proxy:v7.6.0
       container_name: oauth2-proxy
       environment:
         - OAUTH2_PROXY_PROVIDER=keycloak-oidc
         - OAUTH2_PROXY_HTTP_ADDRESS=0.0.0.0:4180
         - OAUTH2_PROXY_UPSTREAMS=file:///dev/null
         - OAUTH2_PROXY_REDIRECT_URL=https://<DOMAIN>/oauth2/callback
         - OAUTH2_PROXY_CLIENT_ID=nginx-oauth2-proxy
         - OAUTH2_PROXY_CLIENT_SECRET=<KEYCLOAK_CLIENT_SECRET>
         - OAUTH2_PROXY_COOKIE_SECRET=<32byte_base64> # 예: `openssl rand -base64 32`
         - OAUTH2_PROXY_OIDC_ISSUER_URL=https://<DOMAIN>/auth/realms/<REALM>
         - OAUTH2_PROXY_SCOPE=openid email profile
         - OAUTH2_PROXY_EMAIL_DOMAINS=*
       networks:
         - backend
     ```

3. Nginx에 인증 연동 location 추가
   - 편집 파일: `nginx/conf.d/default.conf`
   - `/oauth2/` 프록시와 `auth_request` 엔드포인트 추가:
     ```nginx
     # oauth2-proxy endpoints
     location /oauth2/ {
       proxy_pass http://oauth2-proxy;
       proxy_set_header Host $http_host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
     }

     location = /oauth2/auth {
       internal;
       proxy_pass http://oauth2-proxy/auth;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-Proto $scheme;
       proxy_set_header X-Forwarded-Host $http_host;
       proxy_set_header X-Forwarded-Uri $request_uri;
       proxy_set_header X-Original-URI $request_uri;
     }
     ```

   - 보호 대상 경로에 인증 요구 적용(예: `/webui`, `/vscode`, `/toy`):
     ```nginx
     location /webui {
       auth_request /oauth2/auth;
       error_page 401 = /oauth2/start?rd=$scheme://$http_host$request_uri;
       proxy_pass http://openwebui;
       proxy_set_header X-User $upstream_http_x_auth_request_user;
       proxy_set_header X-Email $upstream_http_x_auth_request_email;
       # (기존 프록시 헤더/웹소켓 설정은 유지)
     }

     # 동일 방식으로 /vscode, /toy 에도 적용
     ```

4. 반영/검증
   ```bash
   docker compose up -d --build oauth2-proxy
   docker compose restart nginx
   # 브라우저에서 /webui 접근 시 Keycloak 로그인 → 로그인 성공 후 원래 경로로 리다이렉트
   ```

참고: 직접 Nginx로 OIDC를 처리하는 모듈도 있으나, 단순/안정성 측면에서 `oauth2-proxy` 조합을 권장합니다.

### 2) SSL 활성화(HTTPS)

- 목적: HTTPS로 서비스 제공, HSTS 등 보안 헤더 활성화
- 선택지: (a) 자체 서명(개발용), (b) Let's Encrypt(운영용)

절차 (개발/테스트: 자체 서명 예시)
1. 인증서 생성(호스트에서 실행)
   ```bash
   mkdir -p ssl-certs
   openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
     -keyout ssl-certs/privkey.pem -out ssl-certs/fullchain.pem \
     -subj "/CN=<DOMAIN>"
   ```

2. `nginx/conf.d/ssl.conf` 활성화
   - 파일의 주석을 해제하고 경로가 `/etc/ssl/certs/fullchain.pem`, `/etc/ssl/certs/privkey.pem`를 가리키도록 맞춤(이미 볼륨 마운트됨)
   - `nginx/conf.d/default.conf`에서 HTTP→HTTPS 리다이렉트 주석 해제:
     ```nginx
     # return 301 https://$server_name:26443$request_uri;
     ```
     - 로컬 포트 전달(26443)을 유지할지, 운영에선 443으로 바꿀지 결정

3. 재기동/검증
   ```bash
   docker compose restart nginx
   curl -I https://<DOMAIN>:26443/health -k
   ```

절차 (운영: Let's Encrypt 권장)
1. DNS A레코드로 `<DOMAIN>` → 프록시 호스트 IP 매핑
2. 80/443을 직접 노출하도록 포트 매핑 수정(운영 프로필 권장):
   - `docker-compose.yml`의 `nginx.ports`를 `"80:80", "443:443"`으로 변경
3. 호스트에서 certbot으로 발급 또는 전용 컨테이너 사용
   ```bash
   sudo apt-get install -y certbot python3-certbot-nginx
   sudo certbot certonly --nginx -d <DOMAIN>
   # 발급된 cert 경로를 컨테이너에 마운트하도록 docker-compose 수정 후 nginx 재시작
   ```
4. HSTS, CSP 등 강화 헤더 활성화(`ssl.conf` 참고)

### 3) 도메인 적용

1. `.env` 설정
   ```env
   DOMAIN=<your-domain>
   SSL_ENABLED=true
   ```

2. Keycloak 외부 호스트네임 고정
   - `docker-compose.yml`의 Keycloak 환경변수:
     ```env
     KC_HOSTNAME_URL=https://<DOMAIN>/auth
     KC_HOSTNAME_ADMIN_URL=https://<DOMAIN>/auth
     KC_PROXY=edge
     KC_HTTP_RELATIVE_PATH=/auth
     KC_PROXY_ADDRESS_FORWARDING=true
     ```
   - 반영 후 Keycloak 재기동. 클라이언트 `Valid Redirect URIs`/`Web Origins`에 `https://<DOMAIN>/*` 포함

3. Nginx `server_name` 설정
   - `nginx/conf.d/default.conf`와 `ssl.conf`의 `server_name`을 `<DOMAIN>`으로 변경
   - 운영에서는 80/443 노출, 개발에서는 로컬 포트(26280/26443) 유지 가능

4. 검증
   ```bash
   curl -I https://<DOMAIN>/auth/realms/<REALM>
   curl -I https://<DOMAIN>/webui
   curl -I https://<DOMAIN>/toy/health
   ```

### 체크리스트(다른 모델/사람용 이어서 진행)
- [ ] Keycloak 클라이언트 생성 및 비밀키/리다이렉트 URI 설정 완료
- [ ] `oauth2-proxy` 서비스 추가 및 환경변수 채움
- [ ] Nginx에 `/oauth2/`, `/oauth2/auth` 추가, 보호 경로에 `auth_request` 적용
- [ ] 자체서명/LE 인증서 준비 및 `ssl.conf` 활성화
- [ ] 도메인 `server_name`, Keycloak `KC_HOSTNAME_*` 반영
- [ ] `docker compose up -d --build && docker compose restart nginx` 실행
- [ ] `/webui`, `/vscode`, `/toy` 접근 시 로그인 플로우 정상

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
