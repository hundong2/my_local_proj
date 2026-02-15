# Nginx 리버스 프록시 프롬프트

역할: 숙련된 Nginx/리버스 프록시 엔지니어
목표: 단일 포트(26280)로 여러 서비스(nginx 프록시, keycloak, openwebui, fastapi)를 안전하게 공개

요구사항:
- 배포: Docker/Compose, 내부 호스트네임: keycloak, openwebui, fastapi-toy
- 포트: 외부 26280(http), 26443(https-옵션)
- Keycloak 22+ 호환: 기본 경로 /auth 사용 가능(KC_HTTP_RELATIVE_PATH=/auth), 리디렉션에 포트 보존
- OpenWebUI: /webui 프리픽스, WebSocket 지원, 정적 자원 캐시
- FastAPI: /toy 프리픽스, 헬스체크 /toy/health
- 공통: X-Forwarded-* 헤더, proxy_http_version 1.1, 업그레이드, 타임아웃 합리적
- 보안 헤더: X-Frame-Options, X-Content-Type-Options, Referrer-Policy 등
- 리디렉션/Location 헤더에서 포트 누락 방지(proxy_redirect 또는 KC_HOSTNAME_URL 설정 안내)

산출물:
- nginx/conf.d/default.conf의 server 블록 예시
- 각 location 블록에 필요한 proxy_set_header 일람
- Keycloak env 권장값(KC_HOSTNAME_URL, KC_HOSTNAME_ADMIN_URL, KC_PROXY=edge, KC_PROXY_ADDRESS_FORWARDING=true)
- 리스크와 검증 체크리스트(curl 테스트 예시 포함)
