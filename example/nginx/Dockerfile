# 공식 Nginx 이미지를 기반으로 합니다.
FROM nginx:latest

# 호스트의 nginx.conf 파일을 컨테이너의 설정 디렉토리로 복사합니다.
# default.conf 라는 이름으로 복사하여 Nginx의 기본 서버 설정을 덮어씁니다.
COPY nginx.conf /etc/nginx/conf.d/default.conf
