# 통합 서비스 게이트웨이 프로젝트

## 1. 프로젝트 개요

본 프로젝트는 Docker 기반의 서버 아키텍처를 구축하여, Nginx를 통해 여러 서비스를 단일 게이트웨이로 제공하는 것을 목표로 합니다. 주요 구성 요소는 다음과 같습니다.

- **Nginx:** 리버스 프록시 및 SSL 인증서 처리. URL 경로에 따라 각 백엔드 서비스로 트래픽을 라우팅합니다.
- **Keycloak:** 모든 서비스에 대한 중앙 집중식 인증 및 권한 부여를 제공합니다.
- **Open WebUI:** `/webui` 경로를 통해 접근 가능한 AI 모델 실험용 웹 인터페이스입니다.
- **VSCode Server (code-server):** `/vscode` 경로를 통해 접근 가능한 원격 개발 환경입니다.
- **FastAPI App:** `/toy` 경로를 통해 접근 가능한 간단한 API 서버입니다.

이 `README.md` 문서는 프로젝트가 진행됨에 따라 지속적으로 업데이트될 예정입니다.

## 2. 프로젝트 아키텍처

![Architecture Diagram](https://i.imgur.com/example.png)  <!-- 추후 아키텍처 다이어그램 이미지 링크로 교체 -->

모든 요청은 Nginx를 통해 들어오며, Nginx는 요청된 URL 경로를 분석하여 적절한 내부 서비스로 프록시합니다. Keycloak과의 연동을 통해 인증된 사용자만 서비스에 접근할 수 있도록 제어합니다.

## 3. 사용 방법

**주의:** 아래 단계들을 진행하기 전에 `.env` 파일을 먼저 설정해야 합니다.

```bash
# 1. 저장소 복제
git clone https://github.com/your-repo/your-project.git
cd your-project

# 2. .env 파일 생성 및 설정
# .env 파일에 자신의 도메인, Keycloak 관리자 정보 등을 입력합니다.
# 예시:
# DOMAIN=your-domain.com
# KEYCLOAK_ADMIN=admin
# KEYCLOAK_ADMIN_PASSWORD=admin

# 3. Docker Compose를 사용하여 모든 서비스 실행
docker-compose up -d

# 4. 서비스 접속
- WebUI: https://your-domain.com/webui
- VSCode: https://your-domain.com/vscode
- Toy API: https://your-domain.com/toy
```

## 4. SSL 인증서 설정 (HTTPS)

프로덕션 환경에서는 HTTPS를 사용하는 것이 강력히 권장됩니다. 아래 단계에 따라 SSL을 활성화할 수 있습니다.

1.  **SSL 인증서 준비:**
    *   인증 기관(예: Let's Encrypt)으로부터 발급받은 SSL 인증서와 개인 키를 준비합니다.
    *   `nginx/ssl` 디렉토리(없으면 생성)에 인증서 파일을 위치시킵니다.
        *   인증서: `nginx/ssl/fullchain.pem`
        *   개인 키: `nginx/ssl/privkey.pem`

2.  **Nginx 설정 활성화:**
    *   `nginx/conf.d/default.conf.template` 파일을 엽니다.
    *   파일 하단에 주석 처리된 `server { ... }` 블록(HTTPS용)의 주석을 해제합니다.
    *   (선택 사항) 파일 상단의 HTTP `server` 블록에 있는 `return 301 https://$host$request_uri;` 줄의 주석을 해제하여 모든 HTTP 요청을 HTTPS로 강제 리디렉션할 수 있습니다.

3.  **Docker Compose 포트 확인:**
    *   `docker-compose.yml` 파일에서 `nginx` 서비스의 `ports` 섹션에 `"443:443"`이 포함되어 있는지 확인합니다. (기본적으로 포함되어 있습니다.)

4.  **서비스 재시작:**
    *   설정을 변경한 후, 아래 명령어로 Nginx 서비스를 재시작하여 변경사항을 적용합니다.
        ```bash
        docker-compose up -d --force-recreate nginx
        ```

이제 `https://your-domain.com` 으로 접속하여 HTTPS가 올바르게 적용되었는지 확인할 수 있습니다.

## 5. 프로젝트 구조

```
.
├── docker-compose.yml
├── .env.example
├── fastapi_app
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── nginx
│   ├── conf.d
│   │   └── default.conf.template
│   └── nginx.conf
└── README.md
```

## 6. 진행 상황

- [x] `README.md` 초기화 및 상세화
- [x] 프로젝트 디렉토리 구조 생성
- [x] FastAPI 애플리케이션 생성
- [x] Nginx 설정 파일 생성
- [x] `docker-compose.yml` 파일 생성
- [x] Nginx 리버스 프록시 및 Keycloak 연동 설정
- [x] SSL 설정 방법 문서화
- [x] 최종 검증 및 문서화 완료

## 6. 최종 동작 확인 방법

모든 서비스가 성공적으로 배포된 후, 다음 단계에 따라 동작을 확인할 수 있습니다.

1.  `https://your-domain.com` 으로 접속 시 Keycloak 로그인 페이지로 리디렉션되는지 확인합니다.
2.  Keycloak 관리자 계정으로 로그인 후, 다시 `https://your-domain.com` 으로 접속했을 때 정상적인 페이지가 표시되는지 확인합니다.
3.  `/webui`, `/vscode`, `/toy` 각 경로로 접속했을 때 해당 서비스들이 정상적으로 로드되는지 확인합니다.
4.  인증되지 않은 상태에서 각 서비스 경로로 직접 접근 시도 시 Keycloak 로그인 페이지로 리디렉션되는지 확인합니다.
