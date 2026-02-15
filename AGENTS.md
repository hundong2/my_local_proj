# Web Service 

## Sequence 

1. 개발 목표 

- SSO Authentication ( google ) 을 Keycloak으로 연동. 
- NGINX Reverse Proxy를 사용하여 API Gateway를 구현. 
- fastapi를 사용하여 backend service를 구현. 
- 추후 외부 연결을 위한 ssh 적용 방법 및 dns 서비스 연동을 위한 방법 추가 
- nginx proxy manager를 사용하여 reverse proxy를 구현. 
- ssl 인증서를 자동으로 관리하고 갱신이 되어야 하며 내가 쉽게 리버스 프록시로 서비스들을 확장해 나갈 수 있어야해 . 
- fastapi의 기능은 reverse proxy로 등록 된 서비스들의 목록을 눌러서 해당 서비스로 접속할 수 있는 기능이고, 추가적으로 page 메뉴를 개발하여 특정 웹 서비스를 사용하도록 만들거야 
- grafana, postgresql, redis 를 기반으로 기본적으로 서버에서 서비스하는 내용으로 해당 기술 스택을 주기적으로 학습할 수 있는 환경도 함께 되어야해 
- 이모든 기술 스택을 docker compose 를 통해 한번에 운영 관리가 될 수 있어야하고, 
- 모든 개발관련 지식 및 절차는 README.md에 기록되어야하고, 확장 가능하도록 구성되어야해 

2. 유저 접속 절차

- dns ( hundong2.xyz ) 접속 -> key cloak sso 로그인 -> fastapi dashboard 접속 -> nginx 에 등록 된 reverse proxy로 접속 -> 해당 서비스로 접속 
- nginx의 reverse proxy는 sso 인증을 받은 상태에서 해당 서비스로 접속할 수 있도록 구성해야해 

3. 개발 방법론

- 각 pod 별 해당 개발 stack layer 의 전문가 그룹으로 에이전트를 나눠서 수행하고 
- 접속에 대한 테스트를 진행하는 QA, QE 팀이 있어 테스트를 해야해 
- 이 모든걸 총괄 관리하는 PM이 일정을 관리하고 자동으로 개발 결과에 대해 분석하고 개발 목표가 완전히 이루어질때까지 계속 개발을 진행해야해 
