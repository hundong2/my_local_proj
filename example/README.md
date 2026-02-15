# Keycloak & Nginx Docker-Compose 설정

이 프로젝트는 Docker Compose를 사용하여 Keycloak 인스턴스와 Nginx 리버스 프록시를 함께 실행하는 방법을 안내합니다.

## 사전 요구사항

- Docker
- Docker Compose

## 서버 구성 절차

1.  **환경 변수 설정**
    -   프로젝트 루트의 `.env` 파일을 열고 내용을 수정합니다.
    -   `KEYCLOAK_ADMIN_PASSWORD`: Keycloak 관리자 콘솔에 사용할 강력한 비밀번호를 설정합니다.
    -   `KEYCLOAK_DOMAIN`: Keycloak에 접근할 때 사용할 실제 도메인 이름을 입력합니다. (예: `auth.my-service.com`)

2.  **Nginx 설정 확인 (선택 사항)**
    -   `nginx/nginx.conf` 파일은 기본적으로 `${KEYCLOAK_DOMAIN}`으로 들어오는 모든 요청을 Keycloak 컨테이너로 전달하도록 설정되어 있습니다.
    -   다른 서비스를 추가하려면 아래의 "Nginx 확장 가이드라인" 섹션을 참조하세요.

3.  **서버 실행**
    -   터미널에서 다음 명령어를 실행하여 Docker 컨테이너를 빌드하고 백그라운드에서 실행합니다.
        ```bash
        docker-compose up -d --build
        ```

4.  **접속 확인**
    -   **Keycloak 관리자 콘솔**: 웹 브라우저에서 `http://<your-domain>:<nginx-port>` (예: `http://auth.my-service.com`)으로 접속합니다. `.env` 파일에 설정한 관리자 계정으로 로그인할 수 있습니다.
    -   **Keycloak 직접 접속 (내부 테스트용)**: `http://localhost:10407` 로도 접속이 가능합니다.

## Nginx 확장 가이드라인

Nginx를 확장하여 Keycloak 외에 다른 백엔드 서비스를 추가할 수 있습니다.

**예시: `my-app`이라는 새로운 서비스 추가**

1.  **`docker-compose.yml` 수정**
    -   `services` 섹션에 새로운 서비스(`my-app`)를 추가합니다.

    ```yaml
    services:
      # ... 기존 keycloak, nginx 서비스 ...

      my-app:
        image: your-app-image:latest # 여러분의 애플리케이션 이미지
        container_name: my-app
        networks:
          - keycloak-net
        # ... 기타 설정 ...
    ```

2.  **`nginx/nginx.conf` 수정**
    -   `my-app`으로의 요청을 프록시하기 위한 `server` 블록 또는 `location` 블록을 추가합니다.

    **방법 A: 서브도메인으로 분리 (`app.your-domain.com`)**

    ```nginx
    # Keycloak 서버
    server {
        listen 80;
        server_name ${KEYCLOAK_DOMAIN};

        location / {
            proxy_pass http://keycloak:8080;
            # ... 프록시 헤더 설정 ...
        }
    }

    # My-App 서버
    server {
        listen 80;
        server_name app.your-domain.com;

        location / {
            proxy_pass http://my-app:3000; # my-app이 3000번 포트를 사용한다고 가정
            # ... 프록시 헤더 설정 ...
        }
    }
    ```

    **방법 B: 경로 기반으로 분리 (`your-domain.com/api`)**

    ```nginx
    server {
        listen 80;
        server_name ${KEYCLOAK_DOMAIN};

        # Keycloak 경로
        location / {
            proxy_pass http://keycloak:8080;
            # ... 프록시 헤더 설정 ...
        }

        # My-App 경로
        location /api/ {
            proxy_pass http://my-app:3000/;
            # ... 프록시 헤더 설정 ...
        }
    }
    ```

3.  **설정 적용**
    -   `docker-compose.yml`과 `nginx/nginx.conf` 파일을 수정한 후, 아래 명령어를 실행하여 변경사항을 적용합니다.
        ```bash
        docker-compose up -d --build
        ```