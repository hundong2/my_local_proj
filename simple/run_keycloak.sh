docker run -itd -p 14444:8080 --network keycloak-net \
  --env-file ./keycloak.env \
  -e KC_PROXY=edge \
  --name keycloak quay.io/keycloak/keycloak:26.4.2 start-dev