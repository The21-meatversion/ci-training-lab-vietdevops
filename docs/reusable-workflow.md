# Reusable Workflows — Kiến Trúc và Thiết Kế

## Tổng quan

Reusable Workflow cho phép định nghĩa CI logic một lần và tái sử dụng ở nhiều nơi.

---

## Kiến trúc: Caller → Reusable

```mermaid
graph TB
    subgraph Repo_A ["Repository A (ci-training-lab)"]
        CI_A[".github/workflows/ci.yml<br/>(Caller)"]
    end

    subgraph Repo_B ["Repository B (another-service)"]
        CI_B[".github/workflows/ci.yml<br/>(Caller)"]
    end

    subgraph Shared ["Shared / Same Repo"]
        RW[".github/workflows/reusable-build.yml<br/>(Reusable Workflow)"]
    end

    CI_A -->|"uses: ./reusable-build.yml<br/>with: node-version: '22'"| RW
    CI_B -->|"uses: org/ci-templates/.github/workflows/build.yml@main<br/>with: node-version: '20'"| RW

    RW --> UT[unit-test]
    RW --> LT[lint]
    RW --> SC[security-scan]
    RW --> DB[docker-build]
    RW --> DP[docker-push]

    style RW fill:#9C27B0,color:#fff
    style CI_A fill:#2196F3,color:#fff
    style CI_B fill:#4CAF50,color:#fff
```

---

## Parallel Jobs Flow

```mermaid
gantt
    title Pipeline v12 - Parallel Jobs Timeline
    dateFormat mm:ss
    axisFormat %M:%S

    section unit-test
    checkout & setup    :active, ut1, 00:00, 00:20
    npm ci              :ut2, after ut1, 00:05
    npm test            :ut3, after ut2, 00:30

    section lint
    checkout & setup    :active, lt1, 00:00, 00:20
    npm ci              :lt2, after lt1, 00:05
    eslint              :lt3, after lt2, 00:15

    section security-scan
    checkout            :active, sc1, 00:00, 00:15
    gitleaks            :sc2, after sc1, 00:30
    trivy fs            :sc3, after sc2, 01:00

    section docker-build
    checkout            :active, db1, 00:00, 00:15
    docker build        :db2, after db1, 01:00
    trivy image         :db3, after db2, 01:00

    section docker-push
    wait for all        :crit, dp0, 02:05, 00:01
    login & push        :dp1, after dp0, 00:40
```

---

## workflow_call Syntax

### Caller (`ci.yml`):

```yaml
jobs:
  pipeline:
    uses: ./.github/workflows/reusable-build.yml
    with:
      node-version: '22'        # ← Input parameter
      image-name: ${{ github.repository }}
    secrets: inherit             # ← Pass all secrets automatically
```

### Reusable (`reusable-build.yml`):

```yaml
on:
  workflow_call:
    inputs:
      node-version:
        description: 'Node.js version'
        required: true
        type: string             # string | boolean | number
      image-name:
        required: true
        type: string

jobs:
  unit-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}  # ← Sử dụng input
```

---

## needs — Job Dependencies

```mermaid
graph TD
    A[unit-test] --> E[docker-push]
    B[lint] --> E
    C[security-scan] --> E
    D[docker-build] --> E
    
    A -.->|"if any fails"| SKIP[docker-push SKIPPED]
    B -.-> SKIP
    C -.-> SKIP
    D -.-> SKIP

    style E fill:#9C27B0,color:#fff
    style SKIP fill:#9E9E9E,color:#fff
```

```yaml
docker-push:
  needs: [unit-test, lint, security-scan, docker-build]
  if: github.event_name != 'pull_request'
  # Chỉ chạy khi:
  # 1. Tất cả 4 jobs trên PASS
  # 2. Event là push (không phải PR)
```

---

## So sánh: Composite Action vs Reusable Workflow

| Tính năng | Composite Action | Reusable Workflow |
|-----------|-----------------|-------------------|
| Đơn vị | Steps | Jobs |
| Runner | Dùng chung runner của caller | Runner riêng mỗi job |
| Parallel | Không | Có |
| Secrets | Không được truyền trực tiếp | `secrets: inherit` |
| Cách gọi | `uses: ./action` (trong steps) | `uses: ./workflow` (trong jobs) |
| Use case | Nhóm steps hay dùng | Pipeline hoàn chỉnh |

---

## Reusable Workflow ở Organization Level

```mermaid
graph TB
    subgraph Org ["GitHub Organization"]
        subgraph Templates ["org/ci-templates repository"]
            T1[".github/workflows/node-build.yml"]
            T2[".github/workflows/docker-push.yml"]
            T3[".github/workflows/security-scan.yml"]
        end

        subgraph Services ["Microservices"]
            S1["service-a<br/>uses: org/ci-templates/...node-build.yml@v1"]
            S2["service-b<br/>uses: org/ci-templates/...node-build.yml@v1"]
            S3["service-c<br/>uses: org/ci-templates/...docker-push.yml@v2"]
        end
    end

    T1 --> S1
    T1 --> S2
    T2 --> S3

    style Templates fill:#2196F3,color:#fff
```

### Lợi ích:
- **Single source of truth**: Cập nhật security scan 1 lần → áp dụng cho 50 services
- **Governance**: Security team kiểm soát pipeline template
- **Versioning**: Services có thể pin vào `@v1` hoặc theo `@main`
