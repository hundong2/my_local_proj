import os
import redis
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from typing import Optional
import json
from auth import verify_token, get_current_user

app = FastAPI(title="Hundong2 Dashboard API")

# Redis Connection
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
try:
    r = redis.from_url(REDIS_URL, decode_responses=True)
except Exception as e:
    print(f"Redis connection failed: {e}")
    r = None

@app.get("/")
def read_root():
    return {"message": "Welcome to Hundong2 Dashboard API"}

@app.get("/health")
def health_check():
    return {"status": "ok", "redis": "connected" if r and r.ping() else "disconnected"}

@app.get("/dashboard")
def get_dashboard_data():
    # This would eventually fetch real data from services or DB
    services = [
        {"name": "Keycloak", "url": "http://localhost:8080/auth", "status": "active"},
        {"name": "Nginx Proxy Manager", "url": "http://localhost:81", "status": "active"},
        {"name": "Grafana", "url": "http://localhost/grafana", "status": "active"},
        # Add more services here
    ]
    return JSONResponse(content={"services": services})

@app.get("/public")
def public_endpoint():
    return {"message": "Hello from a public endpoint! You don't need a token here."}

@app.get("/secure", dependencies=[Depends(get_current_user)])
def secure_endpoint(user: dict = Depends(get_current_user)):
    return {"message": f"Hello {user.get('preferred_username', 'User')} from a secure endpoint!", "user_details": user}

@app.get("/me")
def get_current_user_info():
    # Placeholder for user info from SSO token
    return {"user": "guest", "role": "viewer"}
