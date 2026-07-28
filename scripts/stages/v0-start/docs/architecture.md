# Kiến Trúc Hệ Thống — CI Training Lab

## Kiến trúc ứng dụng

```mermaid
graph TB
    subgraph Client ["Client (curl / browser)"]
        C[HTTP Request]
    end

    subgraph App ["Express Application (src/)"]
        A[app.js<br/>Express Server<br/>PORT 3000]
        R[routes/api.js<br/>Router]
        S[services/mathService.js<br/>Business Logic]
        CFG[config.js<br/>Environment Config]
    end

    subgraph Endpoints ["API Endpoints"]
        H[GET /health]
        ADD[GET /add?a=&b=]
        DIV[GET /divide?a=&b=]
    end

    C -->|HTTP GET| A
    A --> R
    R --> H
    R --> ADD
    R --> DIV
    ADD -->|add a, b| S
    DIV -->|divide a, b| S
    A --> CFG

    H -->|{"status":"ok"}| C
    ADD -->|3| C
    DIV -->|5| C
```

---

## Luồng GitHub Actions

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant Runner as GitHub Runner
    participant GHCR as GHCR Registry

    Dev->>GH: git push main
    GH->>Runner: Trigger workflow
    
    rect rgb(200, 230, 255)
        Note over Runner: Job: unit-test
        Runner->>Runner: npm ci
        Runner->>Runner: npm test
    end

    rect rgb(200, 255, 200)
        Note over Runner: Job: lint (parallel)
        Runner->>Runner: npm ci
        Runner->>Runner: npm run lint
    end

    rect rgb(255, 220, 200)
        Note over Runner: Job: security-scan (parallel)
        Runner->>Runner: gitleaks scan
        Runner->>Runner: trivy fs scan
    end

    rect rgb(230, 200, 255)
        Note over Runner: Job: docker-build (parallel)
        Runner->>Runner: docker build
        Runner->>Runner: trivy image scan
    end

    rect rgb(255, 255, 200)
        Note over Runner: Job: docker-push (needs all above)
        Runner->>GHCR: docker login
        Runner->>GHCR: docker push :sha
        Runner->>GHCR: docker push :latest
    end

    GHCR-->>Dev: Image available
```

---

## Cấu trúc GitHub Actions

```mermaid
graph LR
    subgraph Repository ["GitHub Repository"]
        YML[".github/workflows/ci.yml<br/>(Caller)"]
        RYM[".github/workflows/reusable-build.yml<br/>(Reusable)"]
    end

    subgraph Trigger ["Triggers"]
        PUSH[push: main]
        PR[pull_request: main]
    end

    subgraph Jobs ["Jobs (v12)"]
        UT[unit-test]
        LT[lint]
        SC[security-scan]
        DB[docker-build]
        DP[docker-push<br/>needs: all 4]
    end

    PUSH --> YML
    PR --> YML
    YML -->|workflow_call| RYM
    RYM --> UT
    RYM --> LT
    RYM --> SC
    RYM --> DB
    UT --> DP
    LT --> DP
    SC --> DP
    DB --> DP
```

---

## Caching Flow

```mermaid
flowchart TD
    Start[Pipeline Start] --> Check{Cache exists?<br/>key=hash(package-lock.json)}
    
    Check -->|Cache HIT| Restore[Restore cache<br/>~2 seconds]
    Check -->|Cache MISS| Fresh[npm ci from internet<br/>~45 seconds]
    
    Restore --> Install[npm ci<br/>~3 seconds]
    Fresh --> Save[Save cache for next run]
    
    Install --> Run[Run tests/lint]
    Save --> Run
    
    style Restore fill:#4CAF50,color:#fff
    style Fresh fill:#FF9800,color:#fff
    style Save fill:#2196F3,color:#fff
```
