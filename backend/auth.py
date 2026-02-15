from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
import os
import requests
import json

# Keycloak Configuration
KEYCLOAK_URL = os.getenv("KEYCLOAK_URL", "http://keycloak:8080/auth")
REALM = os.getenv("KEYCLOAK_REALM", "hundong")
ALGORITHMS = ["RS256"]

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def get_public_key():
    try:
        url = f"{KEYCLOAK_URL}/realms/{REALM}"
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        return response.json().get("public_key")
    except Exception as e:
        print(f"Error fetching Keycloak public key: {e}")
        return None

def verify_token(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    public_key = get_public_key()
    if not public_key:
        # For dev/testing if Keycloak isn't up yet, maybe allow or fail? 
        # Failing is safer.
        raise HTTPException(status_code=503, detail="Auth service unavailable")

    pem = f"-----BEGIN PUBLIC KEY-----\n{public_key}\n-----END PUBLIC KEY-----"
    
    try:
        payload = jwt.decode(token, pem, algorithms=ALGORITHMS, audience="account")
        # You might want to validate 'aud' or other claims specifically for your client
        return payload
    except JWTError as e:
        print(f"Token validation error: {e}")
        raise credentials_exception

def get_current_user(token_payload: dict = Depends(verify_token)):
    return token_payload
