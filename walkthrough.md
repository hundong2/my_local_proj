# Deployment Walkthrough

I have set up the project structure, Docker Compose configuration, and the FastAPI backend service.

> [!NOTE]
> Keycloak container restart policy has been updated to `restart: always` to handle database connection delays automatically.

## 1. Start Services
Run the following command in your terminal from the project root:

```bash
docker-compose up -d --build
```
Check the status:
```bash
docker-compose ps
```
Ensure all services (`npm`, `keycloak`, `postgres`, `redis`, `grafana`, `backend`) are `Up`.

## 2. Configure Nginx Proxy Manager (NPM)
1.  Open [http://localhost:81](http://localhost:81).
2.  Login with: `admin@example.com` / `changeme`.
3.  Update your email and password as prompted.
4.  **Add Proxy Hosts**:
    -   **Domain**: `localhost`
        -   **Forward Host**: `backend`
        -   **Forward Port**: `8000`
        -   **Custom Locations** (Tab):
            -   Click **Add Location**.
            -   **Define location**: `/auth`
            -   **Forward Host**: `keycloak`
            -   **Forward Port**: `8080`
            -   Click **Add Location**.
            -   **Define location**: `/grafana`
            -   **Forward Host**: `grafana`
            -   **Forward Port**: `3000`

## 3. Configure Keycloak (SSO)
1.  Open [http://localhost:8080/auth/admin/master/console/](http://localhost:8080/auth/admin/master/console/).
2.  Login to Admin Console with `admin` / `admin`.
3.  **Create Realm**:
    -   Click on directory usage (top left) -> **Create Realm**.
    -   Name: `hundong`.
4.  **Setup Google Login**:
    Keycloak에 Google 로그인을 연동하기 위해 Google Cloud Console에서 자격 증명을 발급받아야 합니다.

    **Step 4-1: Google Cloud Console 설정**
    1.  [Google Cloud Console](https://console.cloud.google.com/) 접속 및 로그인.
    2.  새 프로젝트 생성 (예: `Hundong2 Project`).
    3.  **APIs & Services** -> **OAuth consent screen** 이동.
        -   **User Type**: `External` 선택 -> **Create**.
        -   **App Information**: 앱 이름(예: `Hundong2 Auth`), 사용자 지원 이메일 입력.
        -   **Developer Contact Information**: 이메일 입력 -> **Save and Continue**.
        -   나머지 단계는 기본값으로 진행해도 무방합니다.
    4.  **Credentials** (왼쪽 메뉴) -> **Create Credentials** -> **OAuth client ID**.
        -   **Application type**: `Web application`.
        -   **Name**: `Keycloak SSO` (원하는 이름).
        -   **Authorized redirect URIs**:
            Keycloak Identity Provider 설정 페이지에서 `Redirect URI`를 복사해서 붙여넣어야 합니다.
            -   예상 주소: `http://localhost:8080/auth/realms/hundong/broker/google/endpoint`
            -   (정확한 주소는 Keycloak 화면에서 확인 가능)
        -   **Create** 클릭.
    5.  생성된 **Client ID**와 **Client Secret**을 복사해 둡니다.

    **Step 4-2: Keycloak Identity Provider 설정**
    1.  Keycloak Admin Console -> **Identity Providers** (왼쪽 메뉴) -> **Google**.
    2.  **Client ID**: 방금 복사한 값 붙여넣기.
    3.  **Client Secret**: 방금 복사한 값 붙여넣기.
    4.  **Add** 클릭.
    5.  생성 후 상단의 **Redirect URI**를 복사하여, Google Cloud Console의 **Authorized redirect URIs**에 정확히 입력되었는지 다시 확인합니다.
5.  **Create Client**:
    -   **Clients** -> **Create client**.
    -   **Client type**: OpenID Connect.
    -   **Client ID**: `fastapi`.
    -   **Name**: FastAPI Backend.
    -   **Always display in console**: On.
    -   **Root URL**: `http://localhost:8000/` (FastAPI 서버 주소)
    -   **Home URL**: `http://localhost:8000/` (로그인 성공 후 이동할 메인 주소)
    -   Click **Next**.
    -   **Authentication flow**:
        -   **Standard flow**: On (일반적인 로그인 방식)
        -   **Direct access grants**: On (API 테스트용, cURL 등에서 사용)
        -   **Service accounts roles**: Off (필요시 On)
    -   Click **Next**.
    -   **Valid redirect URIs**: `http://localhost:8000/*`
    -   **Web origins**: `*` (또는 `http://localhost:8000`)
    -   Click **Save**.

## 4. Test the System
1.  Navigate to `http://hundong2.xyz` (your dashboard).
2.  The dashboard should show the status of services.
3.  Login via SSO (once implemented in frontend UI) or access protected API endpoints with Bearer token.
