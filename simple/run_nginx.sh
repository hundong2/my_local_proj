docker run -d -p 10407:80 -v "$(pwd)/nginx.conf":/etc/nginx/conf.d/default.conf --name my-nginx nginx:latest
