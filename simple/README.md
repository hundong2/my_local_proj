# Nginx Docker Setup

이 프로젝트는 Keycloak으로 요청을 프록시하는 Nginx Docker 컨테이너를 설정합니다.

## 설정 파일

- `nginx.conf`: Nginx 서버 설정 파일. `www.hundong2.xyz` 도메인으로 들어오는 요청을 `keycloak:14444`로 프록시합니다.
- `Dockerfile`: Nginx 이미지를 빌드하는 데 사용됩니다.

## Docker 이미지 빌드

다음 명령어를 사용하여 Docker 이미지를 빌드합니다:

```bash
docker build -t my-nginx .
```

## Docker 컨테이너 실행

빌드된 이미지를 사용하여 Nginx 컨테이너를 실행합니다. `nginx.conf` 파일은 런타임에 볼륨으로 마운트됩니다.

```bash
docker run -d -p 10407:80 -v "$(pwd)/nginx.conf":/etc/nginx/conf.d/default.conf --name my-nginx my-nginx
```

**참고:**

- `-p 10407:80`: 호스트의 10407 포트를 컨테이너의 80 포트에 매핑합니다.
- `-v "$(pwd)/nginx.conf":/etc/nginx/conf.d/default.conf`: 현재 디렉토리의 `nginx.conf` 파일을 컨테이너 내부의 Nginx 설정 경로에 마운트합니다. 이를 통해 `nginx.conf` 파일을 변경해도 컨테이너를 다시 빌드할 필요 없이 재시작만으로 변경 사항을 적용할 수 있습니다.
- `keycloak`: `nginx.conf` 파일 내에서 `keycloak`은 Keycloak 컨테이너의 서비스 이름으로 가정합니다. Nginx 컨테이너와 Keycloak 컨테이너가 동일한 Docker 네트워크에 있어야 합니다.
