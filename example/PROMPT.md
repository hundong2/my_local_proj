# 서버 실행 가이드

## 1. 환경 변수 설정

`.env` 파일을 열어 `KEYCLOAK_ADMIN_PASSWORD`와 `KEYCLOAK_DOMAIN`을 자신의 환경에 맞게 수정하세요.

## 2. Docker Compose 실행

아래 명령어를 터미널에 입력하여 서버를 시작합니다.

```bash
docker-compose up -d --build
```

## 3. 서버 중지

아래 명령어를 사용하여 실행 중인 컨테이너를 중지하고 제거할 수 있습니다.

```bash
docker-compose down
```
