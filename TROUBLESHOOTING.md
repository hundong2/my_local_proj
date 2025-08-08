# 🔧 Troubleshooting Guide

## 404 Not Found 오류 해결

### 1. 즉시 확인사항

#### Docker 서비스 상태 확인
```bash
# Docker 데몬 상태 확인
docker info

# 컨테이너 상태 확인
docker-compose ps

# 모든 서비스가 "Up" 상태인지 확인
```

#### 서비스 시작/재시작
```bash
# 서비스 시작
docker-compose up -d --build

# 특정 서비스 재시작
docker-compose restart nginx

# 전체 재시작
docker-compose down && docker-compose up -d --build
```

### 2. 단계별 진단

#### Step 1: 기본 연결 테스트
```bash
# Nginx 기본 페이지 확인
curl -I http://localhost:26280/

# 헬스 체크 엔드포인트
curl http://localhost:26280/health
```

#### Step 2: 개별 서비스 확인
```bash
# Keycloak 상태 확인
curl -I http://localhost:26280/auth/realms/master

# FastAPI 확인
curl http://localhost:26280/toy/health

# 각 서비스별 로그 확인
docker-compose logs keycloak
docker-compose logs nginx
docker-compose logs fastapi
```

#### Step 3: 내부 네트워크 연결 확인
```bash
# Nginx에서 백엔드 서비스 접근 테스트
docker-compose exec nginx wget -qO- http://keycloak:8080/auth/realms/master
docker-compose exec nginx wget -qO- http://fastapi:8000/health
```

### 3. 일반적인 문제와 해결책

#### 문제: "502 Bad Gateway"
**원인**: 백엔드 서비스가 준비되지 않음
**해결책**:
```bash
# 서비스 로그 확인
docker-compose logs [service-name]

# Keycloak은 시작에 2-3분 소요
# "Keycloak [version] started" 메시지 대기
```

#### 문제: "404 Not Found"
**원인**: URL 경로 오류 또는 서비스 미응답
**해결책**:
```bash
# 올바른 URL 사용
✓ http://localhost:26280/auth/admin
✓ http://localhost:26280/webui
✓ http://localhost:26280/vscode
✓ http://localhost:26280/toy

# 잘못된 URL
✗ http://localhost:26280/admin
✗ http://localhost:26280/keycloak
```

#### 문제: "Connection refused"
**원인**: 포트가 열리지 않음 또는 방화벽
**해결책**:
```bash
# 포트 사용 확인
netstat -tuln | grep 26280

# Docker 네트워크 확인
docker network ls
docker network inspect [network-name]
```

### 4. 서비스별 특정 문제

#### Keycloak
```bash
# PostgreSQL 연결 확인
docker-compose logs postgres

# Keycloak 초기화 대기
docker-compose logs -f keycloak | grep "Keycloak.*started"

# 데이터베이스 초기화 문제시
docker-compose down -v  # 주의: 데이터 삭제됨
docker-compose up -d
```

#### OpenWebUI
```bash
# OpenWebUI 로그 확인
docker-compose logs openwebui

# 환경변수 확인
docker-compose exec openwebui env | grep -E "OPENAI|OLLAMA"
```

#### VSCode Server (Code Server)
```bash
# 비밀번호 설정 확인
docker-compose logs code-server

# 워크스페이스 마운트 확인
docker-compose exec code-server ls -la /home/coder/workspace
```

#### FastAPI
```bash
# FastAPI 로그 확인
docker-compose logs fastapi

# 수동으로 컨테이너 실행 테스트
docker-compose exec fastapi python -c "import main; print('FastAPI imported successfully')"
```

### 5. 고급 디버깅

#### Nginx 설정 테스트
```bash
# Nginx 설정 문법 확인
docker-compose exec nginx nginx -t

# Nginx 설정 리로드
docker-compose exec nginx nginx -s reload

# 실시간 로그 모니터링
docker-compose exec nginx tail -f /var/log/nginx/access.log
docker-compose exec nginx tail -f /var/log/nginx/error.log
```

#### 네트워크 연결 디버깅
```bash
# 컨테이너 간 네트워크 확인
docker-compose exec nginx ping keycloak
docker-compose exec nginx ping fastapi

# DNS 해석 확인
docker-compose exec nginx nslookup keycloak
```

### 6. 자동화된 디버깅 도구

```bash
# 종합 시스템 테스트
./scripts/test-system.sh

# 404 전용 디버깅
./scripts/debug-404.sh
```

### 7. 환경 초기화 (최후 수단)

```bash
# 모든 컨테이너와 볼륨 삭제 (데이터 손실 주의!)
docker-compose down -v
docker system prune -f

# 이미지 재빌드
docker-compose build --no-cache

# 서비스 재시작
docker-compose up -d
```

### 8. 로그 수집 및 지원 요청

문제가 지속될 경우 다음 정보를 수집:

```bash
# 시스템 정보
docker version
docker-compose version
uname -a

# 서비스 상태
docker-compose ps
docker-compose logs > all-logs.txt

# 네트워크 상태
netstat -tuln | grep 26280
```

### 9. 빠른 문제 해결 체크리스트

- [ ] Docker 데몬이 실행 중인가?
- [ ] 모든 컨테이너가 "Up" 상태인가?
- [ ] Keycloak이 완전히 시작되었나? (2-3분 소요)
- [ ] 올바른 포트 (26280)를 사용하고 있나?
- [ ] URL 경로가 정확한가?
- [ ] 방화벽이나 포트 충돌은 없나?
- [ ] 로그에 에러 메시지가 있나?

### 10. 연락처 및 추가 지원

- 프로젝트 Issues: [Repository URL]
- 문서: README.md
- 설정 가이드: 각 서비스별 디렉토리의 설명 파일
