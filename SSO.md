# Keycloak & Google SSO 심층 학습 가이드

이 문서는 Keycloak을 활용한 Google SSO(Single Sign-On)의 이론적 배경부터 실전 설정 방법까지 단계별로 학습할 수 있도록 구성되었습니다.

---

## 1. 이론적 배경 (Core Concepts)

### 1.1 SSO, OAuth 2.0, OIDC의 관계 및 차이

가장 많이 혼동하는 **SSO**, **OAuth 2.0**, **OIDC**의 개념과 포함 관계를 명확히 정리해 드립니다.

#### 1) 개념 정의
*   **SSO (Single Sign-On)**:
    *   **정의**: "한 번 로그인으로 여러 서비스 이용"이라는 **목표(Goal)**이자 **사용자 경험(UX)**입니다.
    *   **비유**: 놀이공원 자유이용권 (한 번 사면 모든 놀이기구 탑승 가능).
    *   **구현 기술**: SSO를 구현하기 위해 SAML, OIDC 같은 기술이 사용됩니다.
*   **OAuth 2.0 (Open Authorization 2.0)**:
    *   **정의**: "권한 부여(Authorization)"를 위한 **프레임워크**입니다.
    *   **목적**: "내 구글 포토 사진을 다른 앱이 볼 수 있게 허락해줘" (접근 권한 위임).
    *   **한계**: 원래는 '인증(로그인)'을 위한 기술이 아닙니다. 열쇠(Access Token)만 주지, 그 열쇠를 쥔 사람이 누구인지(신분증)는 표준화된 방법으로 알려주지 않습니다.
*   **OIDC (OpenID Connect)**:
    *   **정의**: OAuth 2.0 위에 얹어진 "인증(Authentication)" **표준 프로토콜**입니다.
    *   **공식**: **`OAuth 2.0 + ID Token (신분증) = OIDC`**
    *   **목적**: OAuth 2.0의 한계를 보완하여, "이 열쇠를 쥔 사람은 홍길동이야"라고 알려주는 표준(JWT ID Token)을 정의했습니다.

#### 2) 포함 관계 및 계층
```text
[ SSO (목표/경험) ]
      ^
      | 구현 수단
      |
[ OIDC (인증 프로토콜) ]  <-- 로그인을 처리함 (구글 로그인 등)
      ^
      | 확장 (Extension)
      |
[ OAuth 2.0 (권한 부여 프레임워크) ] <-- 기본 뼈대
```

#### 3) 호텔 출입증 비유 (Analogy)
*   **OAuth 2.0 (Access Token)**: 호텔 방 **키 카드**. (방 문을 열 수 있는 권한은 있지만, 카드에 내 사진이나 이름이 써있진 않음. 누가 주웠어도 문은 열림.)
*   **OIDC (ID Token)**: 호텔 **체크인 기록부(신분증)**. (이 방에 묵는 사람은 송동이고, 나이는 몇 살이고, VIP 등급이다 라는 정보가 적혀 있음.)
*   **SSO**: 호텔 내 **프리패스 시스템**. (체크인 한 번만 하면 수영장, 헬스장, 조식당을 별도 확인 없이 키 카드 하나로 다 이용하는 편리한 시스템.)

---

### 1.2 Keycloak의 역할 (Identity Broker)
Keycloak은 여기서 **Identity Broker** 역할을 합니다.
*   **Identity Provider (IdP)**: 실제 사용자 정보를 가지고 있는 곳 (Google).
*   **Service Provider (SP)**: 로그인이 필요한 애플리케이션 (FastAPI Backend, Grafana 등).
*   **Broker**: SP는 Keycloak만 믿고, Keycloak은 Google을 믿는 구조입니다. 앱은 구글과 직접 통신하지 않고 Keycloak하고만 대화하면 됩니다.

---

## 2. 인증 흐름 (Authentication Flow)

사용자가 "Google로 로그인" 버튼을 눌렀을 때 벌어지는 일입니다.

1.  **User -> App**: "로그인 할래"
2.  **App -> Keycloak**: "인증 안 된 사용자야. 로그인 시켜줘." (리다이렉트)
3.  **Keycloak**: "로그인 방법 골라. (ID/PW 입력? 아니면 Google?)"
4.  **User -> Keycloak**: "Google 선택"
5.  **Keycloak -> Google**: "이 사용자 인증 좀 해줘." (OAuth 2.0 요청, Client ID/Secret 사용)
6.  **Google -> User**: "Keycloak이 네 정보 보려고 하는데 허락해?" (동의 화면)
7.  **User -> Google**: "ㅇㅇ 허락함"
8.  **Google -> Keycloak**: "인증 완료. 여기 인증 코드(Code) 줄게." (리다이렉트)
9.  **Keycloak -> Google**: "코드 줄게, 진짜 토큰(ID Token, Access Token) 줘." (Back-channel 통신)
10. **Google -> Keycloak**: "자, 여기 토큰."
11. **Keycloak -> App**: "인증 끝났어. 내 전용 토큰(Keycloak Token) 줄게."
12. **App**: 토큰 검증 후 로그인 완료.

---

## 3. 실전 설정 가이드 (Step-by-Step)

### Step 1: Google Cloud Console 설정
Google에게 "나 Keycloak이야, 너랑 연동 좀 하자"라고 등록하는 과정입니다.

1.  **[Google Cloud Console](https://console.cloud.google.com/) 접속**.
2.  **새 프로젝트 생성**: 예) `My-Keycloak-Project`.
3.  **OAuth 동의 화면(Consent Screen) 구성**:
    *   `APIs & Services` > `OAuth consent screen`.
    *   **User Type**: `External` (외부 사용자 허용).
    *   앱 이름, 이메일 등 필수 정보 입력.
4.  **자격 증명(Credentials) 생성**:
    *   `Credentials` > `Create Credentials` > `OAuth client ID`.
    *   **Application type**: `Web application`.
    *   **Authorized redirect URIs** (가장 중요!):
        *   Google이 인증 후 다시 돌아올 Keycloak 주소입니다.
        *   형식: `http://<KEYCLOAK_DOMAIN>/auth/realms/<REALM_NAME>/broker/google/endpoint`
        *   로컬 테스트 예시: `http://localhost:8080/auth/realms/hundong/broker/google/endpoint`
    *   생성 후 **Client ID**와 **Client Secret**을 메모장에 복사합니다.

### Step 2: Keycloak Identity Provider 설정
Keycloak에게 "Google이랑 통신할 때 이 비밀번호 써"라고 알려주는 과정입니다.

1.  Keycloak Admin Console 접속 (`http://localhost:8080/auth/admin/`).
2.  왼쪽 메뉴 **Identity Providers** > **Google** 선택.
3.  **Client ID**: 아까 복사한 값 붙여넣기.
4.  **Client Secret**: 아까 복사한 값 붙여넣기.
5.  **Save**.
6.  (확인용) 상단에 보이는 **Redirect URI**가 아까 Google Console에 입력한 것과 정확히 일치하는지 확인.

### Step 3: 애플리케이션(Client) 연동
이제 FastAPI나 프론트엔드 앱이 Keycloak을 사용할 수 있게 설정합니다.

1.  왼쪽 메뉴 **Clients** > **Create**.
2.  **Client ID**: `fastapi` (앱 이름).
3.  **Client Protocol**: `openid-connect`.
4.  **Access Type**: `confidential` (백엔드 앱인 경우) 또는 `public` (SPA 프론트엔드인 경우).
5.  **Valid Redirect URIs**: 로그인 후 돌아올 앱 주소.
    *   예: `http://localhost:8000/*`

---

## 4. 학습 포인트 & 검증 (Self-ChecK)

이 과정을 통해 다음을 이해했는지 스스로 점검해 보세요.

1.  **Callback URL의 중요성**: 왜 `Redirect URI`가 틀리면 `redirect_uri_mismatch` 에러가 나는가?
    *   보안 때문입니다. 등록되지 않은 주소로 토큰을 보내면 탈취될 수 있기 때문입니다.
2.  **Client Secret의 역할**: 왜 Secret은 절대 노출되면 안 되는가?
    *   이게 있으면 누구든 내가 만든 앱인 척 Google에 요청을 보낼 수 있습니다.
3.  **JWT (JSON Web Token)**: Keycloak이 앱에 주는 토큰을 디코딩해 보세요 ([jwt.io](https://jwt.io)).
    *   `iss` (발급자), `sub` (사용자 ID), `exp` (만료 시간) 등의 필드를 확인합니다.

---

## 5. 자주 발생하는 오류 (Troubleshooting)

*   **403 Error: access_denied**: Google Cloud Console에서 `Test Users`에 내 계정을 추가하지 않았거나(테스트 상태일 때), 앱이 아직 게시되지 않은 경우.
*   **redirect_uri_mismatch**: Google Console에 등록한 URI와 Keycloak이 실제로 요청하는 URI가 단 한 글자라도 다를 때 발생. (http vs https, 포트 번호 주의)
*   **Mixed Content Error**: 프론트엔드는 HTTPS인데 Keycloak이 HTTP인 경우 브라우저가 차단할 수 있음. (개발 환경에선 보안 예외 설정 필요)

---

## 6. Keycloak 대안 (Alternatives)

Keycloak은 강력하지만 Java 기반이라 무겁고, 설정이 복잡할 수 있습니다. 프로젝트 목적에 따라 다음 오픈소스 대안을 고려할 수 있습니다.

### 1) Authentik (가장 추천하는 대안)
*   **특징**: Python/Go 기반. 현대적이고 가벼움. UI/UX가 Keycloak보다 직관적임.
*   **장점**: Docker Compose 친화적. 설정 파일 기반 관리 용이. 리소스 사용량이 적음.
*   **추천**: 중소규모 프로젝트, 홈랩(HomeLab), K8s 환경.

### 2) Authelia
*   **특징**: Go 언어 기반 초경량 인증 서버.
*   **장점**: Nginx Proxy Manager와 아주 찰떡궁합. 단순히 "특정 URL 접근 시 로그인 창 띄우기" 기능에 탁월함.
*   **단점**: 풀 스택 Identity Provider(복잡한 사용자 관리, 다양한 소셜 로그인 등)로는 기능이 제한적일 수 있음.

### 3) Ory (Kratos / Hydra)
*   **특징**: 기능을 아주 잘게 쪼개놓은 모듈식 아키텍처.
*   **장점**: 개발자가 입맛대로 필요한 기능만 골라 쓸 수 있음. 확장성 최강.
*   **단점**: 설정 난이도가 매우 높음(초보자 비추천).

---

## 7. 마이그레이션 고려사항 (Keycloak -> Authentik/Authelia)

만약 현재 시스템이 너무 무겁다고 느껴지면, 다음 절차로 마이그레이션을 검토할 수 있습니다.
1.  **사용자 데이터 백업**: Keycloak의 Realm Export 기능을 사용하여 JSON으로 백업.
2.  **연동 방식 변경**: 앱 코드(`auth.py`)는 OIDC 표준을 따르므로, `Discovery URL`만 변경하면 대부분 호환됨.
3.  **Proxy 설정 변경**: Nginx에서 인증 처리 주체를 새로운 컨테이너로 변경.
