from fastapi import FastAPI, Depends, HTTPException, Request, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import JSONResponse, StreamingResponse
import os
import requests
import time
from typing import Optional, Dict, Any
from jose import jwt, JWTError
import logging
from huggingface_hub import snapshot_download
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="FastAPI Toy Server",
    description="A simple toy server with Keycloak authentication",
    version="1.0.0"
    # root_path removed - handled by Nginx
)

security = HTTPBearer()

# Configuration
KEYCLOAK_URL = os.getenv("KEYCLOAK_URL", "http://keycloak:8080")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "master")
KEYCLOAK_CLIENT_ID = os.getenv("KEYCLOAK_CLIENT_ID", "fastapi")
KEYCLOAK_CLIENT_SECRET = os.getenv("KEYCLOAK_CLIENT_SECRET", "fastapi-secret")
HF_CACHE_DIR = os.getenv("HF_HOME", str(Path.home() / ".cache" / "huggingface"))

# Cache for public keys
public_keys_cache = {"keys": {}, "last_updated": 0}

def get_public_keys():
    """Get public keys from Keycloak with caching"""
    current_time = time.time()
    if current_time - public_keys_cache["last_updated"] > 3600:  # Cache for 1 hour
        try:
            url = f"{KEYCLOAK_URL}/auth/realms/{KEYCLOAK_REALM}/.well-known/openid_configuration"
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            config = response.json()
            
            jwks_uri = config["jwks_uri"]
            jwks_response = requests.get(jwks_uri, timeout=10)
            jwks_response.raise_for_status()
            jwks = jwks_response.json()
            
            public_keys_cache["keys"] = {key["kid"]: key for key in jwks["keys"]}
            public_keys_cache["last_updated"] = current_time
            logger.info("Updated public keys cache")
            
        except Exception as e:
            logger.error(f"Failed to update public keys: {e}")
            if not public_keys_cache["keys"]:
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail="Unable to verify tokens - authentication service unavailable"
                )
    
    return public_keys_cache["keys"]

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """Verify JWT token from Keycloak"""
    token = credentials.credentials
    
    try:
        # Get public keys
        public_keys = get_public_keys()
        
        # Decode token header to get key ID
        unverified_header = jwt.get_unverified_header(token)
        key_id = unverified_header.get("kid")
        
        if key_id not in public_keys:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token - key not found"
            )
        
        # Get the key
        public_key = public_keys[key_id]
        
        # Verify token
        payload = jwt.decode(
            token,
            public_key,
            algorithms=["RS256"],
            audience=KEYCLOAK_CLIENT_ID,
            issuer=f"{KEYCLOAK_URL}/auth/realms/{KEYCLOAK_REALM}"
        )
        
        return payload
        
    except JWTError as e:
        logger.error(f"JWT verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    except Exception as e:
        logger.error(f"Token verification error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token verification failed"
        )

# Public endpoints
@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to FastAPI Toy Server",
        "version": "1.0.0",
        "status": "running",
        "timestamp": time.time()
    }

@app.get("/health")
@app.head("/health")
async def health():
    """Health check endpoint (supports both GET and HEAD)"""
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "keycloak_url": KEYCLOAK_URL,
        "realm": KEYCLOAK_REALM
    }

# Protected endpoints (require authentication)
@app.get("/protected")
async def protected_endpoint(user: Dict[str, Any] = Depends(verify_token)):
    """Protected endpoint that requires authentication"""
    return {
        "message": "This is a protected endpoint",
        "user": {
            "sub": user.get("sub"),
            "preferred_username": user.get("preferred_username"),
            "email": user.get("email"),
            "roles": user.get("realm_access", {}).get("roles", [])
        },
        "timestamp": time.time()
    }

@app.get("/user/profile")
async def user_profile(user: Dict[str, Any] = Depends(verify_token)):
    """Get user profile information"""
    return {
        "user_id": user.get("sub"),
        "username": user.get("preferred_username"),
        "email": user.get("email"),
        "first_name": user.get("given_name"),
        "last_name": user.get("family_name"),
        "roles": user.get("realm_access", {}).get("roles", []),
        "email_verified": user.get("email_verified", False),
        "token_issued_at": user.get("iat"),
        "token_expires_at": user.get("exp")
    }

@app.post("/data")
async def create_data(request: Request, user: Dict[str, Any] = Depends(verify_token)):
    """Create data endpoint"""
    body = await request.json()
    
    return {
        "message": "Data created successfully",
        "data": body,
        "created_by": user.get("preferred_username"),
        "timestamp": time.time()
    }

@app.get("/data")
async def get_data(user: Dict[str, Any] = Depends(verify_token)):
    """Get data endpoint"""
    return {
        "message": "Sample data",
        "data": [
            {"id": 1, "name": "Item 1", "value": "Value 1"},
            {"id": 2, "name": "Item 2", "value": "Value 2"},
            {"id": 3, "name": "Item 3", "value": "Value 3"}
        ],
        "requested_by": user.get("preferred_username"),
        "timestamp": time.time()
    }

@app.get("/admin/users")
async def admin_users(user: Dict[str, Any] = Depends(verify_token)):
    """Admin endpoint - requires admin role"""
    user_roles = user.get("realm_access", {}).get("roles", [])
    
    if "admin" not in user_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin role required"
        )
    
    return {
        "message": "User management data",
        "users": [
            {"id": 1, "username": "user1", "status": "active"},
            {"id": 2, "username": "user2", "status": "inactive"}
        ],
        "accessed_by": user.get("preferred_username"),
        "timestamp": time.time()
    }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.detail,
            "status_code": exc.status_code,
            "timestamp": time.time(),
            "path": str(request.url)
        }
    )

@app.exception_handler(500)
async def internal_server_error_handler(request: Request, exc: Exception):
    logger.error(f"Internal server error: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "status_code": 500,
            "timestamp": time.time(),
            "path": str(request.url)
        }
    )

# ----------------------
# Hugging Face utilities
# ----------------------

@app.get("/hf/models/download")
async def download_model_endpoint(model_id: str, revision: str | None = None, user: Dict[str, Any] = Depends(verify_token)):
    """Trigger server-side download of a Hugging Face model snapshot to the shared cache.

    Query params:
    - model_id: e.g. "TheBloke/Mistral-7B-Instruct-v0.2-GGUF"
    - revision: optional commit hash or tag
    """
    try:
        local_path = snapshot_download(
            repo_id=model_id,
            revision=revision,
            cache_dir=HF_CACHE_DIR,
            local_files_only=False,
            resume_download=True,
        )
        return {"status": "ok", "cached_path": str(local_path)}
    except Exception as e:
        logger.exception("HF download failed")
        raise HTTPException(status_code=500, detail=f"Download failed: {e}")


@app.get("/hf/files/stream")
async def stream_cached_file(relative_path: str, user: Dict[str, Any] = Depends(verify_token)):
    """Stream a cached file from the HF cache directory by relative path under HF_CACHE_DIR."""
    base = Path(HF_CACHE_DIR)
    target = (base / relative_path).resolve()
    if not str(target).startswith(str(base.resolve())):
        raise HTTPException(status_code=400, detail="Invalid path")
    if not target.exists() or not target.is_file():
        raise HTTPException(status_code=404, detail="File not found")

    def file_iterator(chunk_size: int = 1024 * 1024):
        with open(target, "rb") as f:
            while True:
                chunk = f.read(chunk_size)
                if not chunk:
                    break
                yield chunk

    return StreamingResponse(file_iterator(), media_type="application/octet-stream")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
