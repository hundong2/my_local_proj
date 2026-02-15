# Nginx 하드닝 체크리스트 프롬프트

역할: 보안 엔지니어
목표: Nginx 리버스 프록시 하드닝

점검항목:
- 보안 헤더: X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy 템플릿
- 업스트림 타임아웃/버퍼/크기 제한(client_max_body_size 등)
- TLS(선택): 최저 TLS 버전, 보안 cipher, HSTS 주의
- 경로 기반 프록시에서 오픈 리다이렉트, 포트 누락, Host 헤더 스푸핑 방지
- WebSocket 업그레이드 안전성
- 캐시 정책(정적/동적 구분)

산출물:
- 설정 diff 제안과 함께 문제점 표시
- 테스트 커맨드(curl, nmap, sslyze) 제공
