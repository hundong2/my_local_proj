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

from fastapi.responses import HTMLResponse

@app.get("/", response_class=HTMLResponse)
def read_root():
    return """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hundong2 SSO Demo</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background-color: #f4f4f4; }
        .container { background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .btn { display: inline-block; padding: 10px 20px; color: white; border: none; border-radius: 5px; cursor: pointer; text-decoration: none; font-size: 1rem; }
        .btn-login { background-color: #007bff; }
        .btn-logout { background-color: #dc3545; }
        .btn-api { background-color: #28a745; margin-top: 10px; }
        .hidden { display: none; }
        #apiResult { margin-top: 20px; padding: 10px; background: #eee; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hundong2 SSO Test</h1>
        <p>Keycloak OIDC Login Demonstration</p>

        <div id="unauthenticated">
            <button id="loginBtn" class="btn btn-login">Login with Keycloak</button>
        </div>

        <div id="authenticated" class="hidden">
            <p>Welcome, <strong id="username">User</strong>!</p>
            <button id="apiBtn" class="btn btn-api">Call Secure API</button>
            <button id="logoutBtn" class="btn btn-logout">Logout</button>
            <div id="apiResult" class="hidden"></div>
        </div>
    </div>

    <script src="http://localhost:8080/auth/js/keycloak.js"></script>
    <script>
        const keycloakConfig = {
            url: 'http://localhost:8080/auth',
            realm: 'hundong',
            clientId: 'fastapi'
        };

        const keycloak = new Keycloak(keycloakConfig);

        keycloak.init({ onLoad: 'check-sso' }).then(authenticated => {
            if (authenticated) {
                document.getElementById('unauthenticated').classList.add('hidden');
                document.getElementById('authenticated').classList.remove('hidden');
                document.getElementById('username').textContent = keycloak.tokenParsed.preferred_username || 'User';
            } else {
                document.getElementById('unauthenticated').classList.remove('hidden');
                document.getElementById('authenticated').classList.add('hidden');
            }
        }).catch(err => console.error(err));

        document.getElementById('loginBtn').onclick = () => keycloak.login();
        document.getElementById('logoutBtn').onclick = () => keycloak.logout();

        document.getElementById('apiBtn').onclick = () => {
            fetch('http://localhost:8000/secure', {
                headers: { 'Authorization': 'Bearer ' + keycloak.token }
            })
            .then(res => res.json())
            .then(data => {
                const el = document.getElementById('apiResult');
                el.classList.remove('hidden');
                el.innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            })
            .catch(err => alert('API Error: ' + err));
        };
    </script>
</body>
</html>
    """

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
