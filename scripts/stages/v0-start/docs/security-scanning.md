# Security Scanning — Trivy & Gitleaks

## Tổng quan

CI Training Lab sử dụng 2 công cụ bảo mật:

| Tool | Phát hiện | Bài học |
|------|-----------|---------|
| **Trivy** | CVE trong dependencies, Dockerfile issues, OS packages | v7, v8 |
| **Gitleaks** | Hardcoded secrets trong source code và git history | v9, v10 |

---

## Trivy Scan Flow

```mermaid
flowchart TD
    Start[CI Pipeline] --> FS[Trivy Filesystem Scan<br/>scan-type: fs]
    Start --> DB2[Docker Build]
    
    FS --> FS_Check{Tìm thấy<br/>CRITICAL/HIGH CVE?}
    DB2 --> IS[Trivy Image Scan<br/>scan-type: image]
    
    FS_Check -->|Có| FS_FAIL[❌ Pipeline FAIL<br/>exit-code: 1]
    FS_Check -->|Không| FS_PASS[✅ Filesystem OK]
    
    IS --> IS_Check{Tìm thấy<br/>CRITICAL/HIGH CVE?}
    IS_Check -->|Có| IS_FAIL[❌ Pipeline FAIL<br/>exit-code: 1]
    IS_Check -->|Không| IS_PASS[✅ Image OK]
    
    FS_PASS --> Continue[Tiếp tục pipeline]
    IS_PASS --> Continue

    style FS_FAIL fill:#F44336,color:#fff
    style IS_FAIL fill:#F44336,color:#fff
    style FS_PASS fill:#4CAF50,color:#fff
    style IS_PASS fill:#4CAF50,color:#fff
```

### Trivy Filesystem Scan

Quét:
- `package.json` / `package-lock.json` — npm vulnerabilities
- `requirements.txt` — Python vulnerabilities
- Go modules, Gemfiles, Composer, v.v.

```yaml
- uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
    format: 'table'
    exit-code: '1'          # Fail pipeline nếu tìm thấy
    severity: 'CRITICAL,HIGH'
```

### Trivy Image Scan

Quét:
- OS packages (alpine, debian, ubuntu)
- Application dependencies trong image
- Dockerfile misconfigurations

```yaml
- uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'ci-training-lab:${{ github.sha }}'
    format: 'table'
    exit-code: '1'
    severity: 'CRITICAL,HIGH'
```

### CVE Severity Levels

```mermaid
graph LR
    C[CRITICAL<br/>CVSS 9.0-10.0<br/>Fix ngay!] --> H
    H[HIGH<br/>CVSS 7.0-8.9<br/>Fix trong sprint] --> M
    M[MEDIUM<br/>CVSS 4.0-6.9<br/>Lên kế hoạch fix] --> L
    L[LOW<br/>CVSS 0.1-3.9<br/>Theo dõi]
    N[NONE<br/>CVSS 0.0<br/>Informational]

    style C fill:#F44336,color:#fff
    style H fill:#FF9800,color:#fff
    style M fill:#FFEB3B
    style L fill:#4CAF50,color:#fff
    style N fill:#9E9E9E,color:#fff
```

---

## Gitleaks Scan Flow

```mermaid
flowchart TD
    Start[CI Pipeline] --> GL[Gitleaks Action]
    GL --> Fetch[Fetch full git history<br/>fetch-depth: 0]
    Fetch --> Scan[Scan all commits<br/>+ staged changes]
    
    Scan --> Rules{Match any rule?}
    
    Rules -->|Default rules| DR[AWS keys, GitHub tokens,<br/>Stripe keys, JWT, etc.]
    Rules -->|Custom rules| CR[hardcoded-api-key rule<br/>từ .gitleaks.toml]
    
    DR --> Found{Tìm thấy?}
    CR --> Found
    
    Found -->|Có| FAIL[❌ Pipeline FAIL<br/>Hiển thị: file, line, secret value]
    Found -->|Không| PASS[✅ No secrets found]

    style FAIL fill:#F44336,color:#fff
    style PASS fill:#4CAF50,color:#fff
```

### Custom rule trong .gitleaks.toml

```toml
[[rules]]
id = "hardcoded-api-key"
regex = '''(?i)(api[_-]?key)\s*[=:]\s*["']([^"'\s]{8,})["']'''
secretGroup = 2
```

Pattern này phát hiện:
```javascript
const API_KEY = "sk-training-hardcoded-key..."  // ← Match!
const api_key = "any-long-string-here"           // ← Match!
const API_KEY = "YOUR_KEY_HERE"                  // ← Allowlisted
```

### Vì sao cần `fetch-depth: 0`?

```mermaid
sequenceDiagram
    participant GH as GitHub
    participant Runner as Runner
    participant GL as Gitleaks

    Note over GH: Branch with 50 commits
    Note over GH: Commit 47: added secret
    Note over GH: Commit 48: removed secret
    Note over GH: Commit 50: current HEAD

    GH->>Runner: Checkout (default depth=1)
    Note over Runner: Only has commit 50!

    Runner->>GL: Scan
    GL-->>Runner: ✅ No secret found
    Note over Runner: FALSE NEGATIVE! Secret exists in history

    GH->>Runner: Checkout (fetch-depth: 0)
    Note over Runner: Has ALL 50 commits

    Runner->>GL: Scan all history
    GL-->>Runner: ❌ FOUND secret in commit 47!
    Note over Runner: Correct detection!
```

---

## Hành động khi phát hiện secret

```mermaid
flowchart LR
    Found[Secret phát hiện<br/>trong git history] --> Rotate[1. Rotate ngay<br/>Đổi key/password<br/>Revoke token cũ]
    Rotate --> Notify[2. Thông báo<br/>Security team<br/>Audit access logs]
    Notify --> Clean[3. Clean history<br/>git filter-repo<br/>HOẶC tạo repo mới]
    Clean --> Prevent[4. Phòng ngừa<br/>pre-commit hooks<br/>Gitleaks CI]

    style Found fill:#F44336,color:#fff
    style Rotate fill:#FF9800,color:#fff
    style Notify fill:#FFEB3B
    style Clean fill:#2196F3,color:#fff
    style Prevent fill:#4CAF50,color:#fff
```

> ⚠️ **Quan trọng**: Xoá secret khỏi code và commit lại KHÔNG đủ.  
> Secret vẫn tồn tại trong git history và có thể bị tìm thấy bằng `git log -p`.
