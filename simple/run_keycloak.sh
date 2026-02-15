docker run -itd -p 14444:8080 --network keycloak-net \
  --env-file ./keycloak.env \
  --name keycloak quay.io/keycloak/keycloak:26.4.2 start-dev
