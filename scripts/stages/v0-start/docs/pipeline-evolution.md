# Pipeline Evolution — Từ v1 đến v12

Mỗi tag thêm một tính năng vào CI pipeline. Diagram dưới đây cho thấy sự phát triển qua từng bài học.

## v1 — Unit Tests

```mermaid
graph LR
    A[Checkout] --> B[Setup Node] --> C[npm ci] --> D[npm test]
    style D fill:#4CAF50,color:#fff
```

## v3 — Thêm ESLint

```mermaid
graph LR
    A[Checkout] --> B[Setup Node] --> C[npm ci] --> D[npm test] --> E[npm run lint]
    style E fill:#FF9800,color:#fff
```

## v5 — Thêm Cache

```mermaid
graph LR
    A[Checkout] --> B["Setup Node<br/>(cache: npm)"] --> C[npm ci<br/>~3s cached] --> D[npm test] --> E[npm run lint]
    style B fill:#2196F3,color:#fff
    style C fill:#2196F3,color:#fff
```

## v6 — Docker Build

```mermaid
graph LR
    A[Checkout] --> B[Setup Node+cache] --> C[npm ci] --> D[npm test] --> E[lint] --> F[docker build]
    style F fill:#9C27B0,color:#fff
```

## v7 — Trivy Security Scan

```mermaid
graph LR
    A[Checkout] --> B[Setup Node+cache] --> C[npm ci] --> D[npm test] --> E[lint] --> F[trivy fs] --> G[docker build] --> H[trivy image]
    style F fill:#F44336,color:#fff
    style H fill:#F44336,color:#fff
```

## v9 — Gitleaks Secret Scan

```mermaid
graph LR
    A[Checkout<br/>fetch-depth:0] --> B[Setup Node] --> C[npm ci] --> D[npm test] --> E[lint] --> F[gitleaks] --> G[trivy fs] --> H[docker build] --> I[trivy image]
    style F fill:#E91E63,color:#fff
```

## v11 — Push to GHCR

```mermaid
graph LR
    A[Checkout] --> B[Setup Node] --> C[npm ci] --> D[npm test] --> E[lint] --> F[gitleaks] --> G[trivy fs] --> H[docker login] --> I["build+push<br/>→ ghcr.io"] --> J[trivy image]
    style H fill:#00BCD4,color:#fff
    style I fill:#00BCD4,color:#fff
```

## v12 — Parallel Jobs + Reusable Workflow

```mermaid
graph TD
    Caller[ci.yml<br/>workflow_call] --> RW[reusable-build.yml]
    
    RW --> UT["Job: unit-test<br/>checkout → npm ci → npm test"]
    RW --> LT["Job: lint<br/>checkout → npm ci → lint"]
    RW --> SC["Job: security-scan<br/>checkout → gitleaks → trivy fs"]
    RW --> DB["Job: docker-build<br/>checkout → docker build → trivy image"]
    
    UT --> DP["Job: docker-push<br/>needs: [unit-test, lint, security-scan, docker-build]<br/>→ ghcr.io push"]
    LT --> DP
    SC --> DP
    DB --> DP

    style UT fill:#4CAF50,color:#fff
    style LT fill:#4CAF50,color:#fff
    style SC fill:#FF9800,color:#fff
    style DB fill:#2196F3,color:#fff
    style DP fill:#9C27B0,color:#fff
```

## So sánh thời gian (ước tính)

| Version | Jobs | Thời gian ước tính |
|---------|------|-------------------|
| v1 | 1 job sequential | 2 phút |
| v3 | 1 job sequential | 2.5 phút |
| v5 | 1 job (có cache) | 1.5 phút (cached) |
| v7 | 1 job (+ trivy) | 4 phút |
| v9 | 1 job (+ gitleaks) | 5 phút |
| v11 | 1 job (+ push) | 6 phút |
| v12 | 5 jobs parallel | ~4 phút (faster!) |
