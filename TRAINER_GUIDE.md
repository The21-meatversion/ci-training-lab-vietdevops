# TRAINER GUIDE — CI Training Lab với GitHub Actions

> Tài liệu này dành cho **Trainer/Instructor**.  
> Học viên nên tự khám phá vấn đề trước khi xem hướng dẫn.

---

## Tổng quan khoá học

| Thông tin | Chi tiết |
|-----------|---------|
| **Thời lượng** | 1-2 ngày (8-16 tiếng) |
| **Trình độ** | Junior/Mid DevOps, Backend developers |
| **Yêu cầu** | Biết cơ bản Git, Node.js, Docker |
| **Kết quả** | Pipeline CI hoàn chỉnh với bảo mật |

### Cách sử dụng repository này

1. Chạy `bash scripts/init-git-history.sh` để tạo git history
2. Push lên GitHub: `git push --all && git push --tags`
3. Học viên clone và làm theo hướng dẫn từng bài
4. Mỗi bài = checkout một tag → quan sát → sửa → tiếp tục

---

## Bài 0 — Khởi tạo dự án (`v0-start`)

### Mục tiêu học tập
- Hiểu cấu trúc dự án Node.js/Express chuẩn
- Biết cách chạy ứng dụng local
- Hiểu tại sao cần CI (hiện chưa có CI)

### Bước thực hiện cho học viên
```bash
git checkout v0-start
npm install
npm start
curl http://localhost:3000/health
curl "http://localhost:3000/add?a=5&b=3"
```

### Kết quả mong đợi
- Ứng dụng chạy thành công trên port 3000
- Không có CI pipeline nào
- Dockerfile tồn tại nhưng chưa tối ưu

### Thảo luận

**Câu hỏi gợi mở:**
- Điều gì xảy ra nếu developer push code lỗi lên main branch mà không có CI?
- Làm thế nào để đảm bảo code luôn hoạt động trước khi merge?
- Dockerfile hiện tại có vấn đề gì? (FROM node:latest, chạy root, không có .dockerignore...)

### Lỗi hay gặp
- `npm install` fail vì Node.js version không đúng → cần Node 18+
- Port 3000 đã bị dùng → set `PORT=3001 npm start`

---

## Bài 1 — Thêm Unit Tests vào CI (`v1-unit-test-fail`)

### Mục tiêu học tập
- Viết unit tests với Jest
- Tạo GitHub Actions workflow cơ bản
- Hiểu cấu trúc workflow YAML

### Kết quả pipeline dự kiến
```
❌ PIPELINE FAIL
  ✅ Checkout
  ✅ Setup Node.js
  ✅ Install dependencies
  ❌ Run unit tests — 1 test FAILED
```

### Lý do thất bại
Test `cộng hai số dương` mong đợi `add(1, 2)` trả về `4` nhưng hàm trả về `3`.

```
FAIL tests/mathService.test.js
  ● mathService - add() › cộng hai số dương
    Expected: 4
    Received: 3
```

### Hướng dẫn điều tra cho học viên
```bash
git checkout v1-unit-test-fail
npm test
# Đọc kỹ error message — dòng nào fail? Expected vs Received là gì?
```

### Cách sửa
```bash
# Mở tests/mathService.test.js
# Dòng: expect(add(1, 2)).toBe(4)
# Sửa: expect(add(1, 2)).toBe(3)
```

### Thảo luận
- Test fail trong CI có phải là điều xấu? (Không — đó là mục đích của CI!)
- Tại sao `npm ci` thay vì `npm install`?
- Sự khác biệt giữa `push` và `pull_request` triggers?

### Best practices
- Luôn viết tests trước khi thêm vào CI
- Test failure = vấn đề trong code, không phải vấn đề của pipeline
- Dùng `npm ci` trong CI để đảm bảo deterministic builds

---

## Bài 2 — Sửa Unit Tests (`v2-unit-test-fix`)

### Mục tiêu học tập
- Hiểu vòng lặp CI: fail → investigate → fix → pass
- Hiểu test coverage là gì
- Biết các loại test assertion phổ biến

### Kết quả pipeline dự kiến
```
✅ PIPELINE PASS
  ✅ Checkout (2s)
  ✅ Setup Node.js (15s)
  ✅ Install dependencies (20s)
  ✅ Run unit tests — 10 tests passed (5s)
```

### Thảo luận
- Coverage report cho biết gì? (`coverage/lcov-report/index.html`)
- Nên nhắm tới coverage bao nhiêu %? (80%+ là thực tế)
- Khi nào test là "đủ"?

### Best practices
- Tests phải mô tả hành vi, không phải implementation
- Test cả happy path lẫn error cases
- Test names nên là documentation tự mô tả

---

## Bài 3 — Thêm ESLint (`v3-lint-fail`)

### Mục tiêu học tập
- Hiểu linting là gì và tại sao cần
- Cấu hình ESLint cho Node.js project
- Tích hợp lint vào CI pipeline

### Kết quả pipeline dự kiến
```
❌ PIPELINE FAIL
  ✅ Checkout
  ✅ Setup Node.js
  ✅ Install dependencies
  ✅ Run unit tests
  ❌ Run ESLint

Error: src/routes/api.js:8:7 error 'unusedConfig' is assigned a value but never used
Error: src/routes/api.js:4:1 error Missing semicolon
(12 errors total)
```

### Lý do thất bại
Source files có 2 loại lỗi:
1. **Missing semicolons** (`semi: error`) — cả file thiếu dấu `;`
2. **Unused variables** (`no-unused-vars: error`) — `unusedConfig`, `version`

### Hướng dẫn điều tra
```bash
git checkout v3-lint-fail
npm run lint
# Đọc từng error: file:line:col errorType 'description'
```

### Cách sửa
```bash
# Tự động sửa những gì có thể
npm run lint:fix

# Sửa thủ công phần còn lại (unused variables)
# Xoá const unusedConfig = ...
# Xoá const version = ...
```

### Thảo luận
- Tại sao lint là bước riêng, không gộp vào tests?
- Khi nào nên dùng `eslint-disable` comment?
- Rule nào là "must have" cho production code?

### Common mistakes
- Chạy `npm run lint:fix` fix semicolons nhưng KHÔNG fix unused vars → học viên cần sửa thủ công
- Nhầm giữa `warning` và `error` — chỉ `error` mới làm pipeline fail

---

## Bài 4 — Sửa Lint Errors (`v4-lint-fix`)

### Mục tiêu học tập
- Clean code là code dễ đọc, maintain
- Tự động enforce code style trong team

### Kết quả pipeline dự kiến
```
✅ PIPELINE PASS — tất cả steps đều xanh
```

### Thảo luận
- Lint config nên strict đến mức nào?
- Pre-commit hooks với `husky` và `lint-staged` vs CI lint
- Code style conventions: tại sao quan trọng hơn style nào đúng

---

## Bài 5 — Caching Dependencies (`v5-cache`)

### Mục tiêu học tập
- Hiểu tại sao caching quan trọng
- Cấu hình npm cache trong GitHub Actions
- Đo lường hiệu quả của caching

### Thay đổi quan trọng trong ci.yml
```yaml
# TRƯỚC (v4):
- uses: actions/setup-node@v4
  with:
    node-version: '22'

# SAU (v5):
- uses: actions/setup-node@v4
  with:
    node-version: '22'
    cache: 'npm'      # ← Dòng này thêm cache
```

### Kết quả pipeline dự kiến
- **Lần 1** (cache miss): `npm ci` ~ 45-60 giây
- **Lần 2+** (cache hit): `npm ci` ~ 3-5 giây

### Thảo luận
- Cache key là gì và hoạt động như thế nào? (hash của package-lock.json)
- Khi nào cache invalidated? (khi package-lock.json thay đổi)
- So sánh: `actions/cache` manual vs `cache` trong setup-node

### Bài tập
- Commit 1 thay đổi nhỏ (không sửa package.json) → quan sát cache hit
- Thêm 1 dependency mới → quan sát cache miss và rebuild

---

## Bài 6 — Docker Build trong CI (`v6-docker-build`)

### Mục tiêu học tập
- Build Docker image trong CI pipeline
- Tag image với git SHA để traceability
- Hiểu Dockerfile hiện tại có những vấn đề gì

### Thảo luận
- Tại sao tag image với `${{ github.sha }}`?
- Image `ci-training-lab:abc123` được lưu ở đâu? (local runner, bị xoá sau job)
- Dockerfile `FROM node:latest` có vấn đề gì?

### Quan sát để chuẩn bị cho bài tiếp
```bash
# Sau khi build image locally
docker build -t ci-training-lab .
docker images ci-training-lab  # Xem size — sẽ khá lớn
docker run --rm ci-training-lab whoami  # Sẽ thấy "root"
```

---

## Bài 7 — Quét Bảo Mật với Trivy (`v7-trivy-fail`)

### Mục tiêu học tập
- Hiểu CVE (Common Vulnerabilities and Exposures) là gì
- Sử dụng Trivy để quét filesystem và Docker image
- Phân biệt CRITICAL, HIGH, MEDIUM, LOW severity

### Kết quả pipeline dự kiến
```
❌ PIPELINE FAIL
  ✅ Tests, Lint
  ❌ Scan filesystem with Trivy
    CRITICAL: lodash 4.17.4 — CVE-2019-10744 Prototype Pollution
  (pipeline dừng, không tiếp tục)
```

### Lý do thất bại
1. **CVE-2019-10744** trong `lodash@4.17.4` (Prototype Pollution — CRITICAL)
2. Docker image scan: `node:latest` có nhiều known vulnerabilities

### Hướng dẫn điều tra
```bash
# Cài Trivy local
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Quét filesystem
trivy fs --severity CRITICAL,HIGH .

# Quét image
docker build -t test .
trivy image --severity CRITICAL,HIGH test
```

### Thảo luận
- `exit-code: '1'` có nghĩa là gì trong Trivy action?
- Tại sao `severity: 'CRITICAL,HIGH'` không phải `MEDIUM,LOW`?
- CVE score (CVSS) là gì?
- Khi nào nên dùng `ignore-unfixed: true`?

### Common mistakes
- Học viên bỏ qua warning, chỉ quan tâm error → nhắc: trong bảo mật không có "bỏ qua sau"
- Nghĩ rằng chỉ cần upgrade là xong → discuss: sometimes no fix available, need to find alternatives

---

## Bài 8 — Sửa Vấn Đề Bảo Mật (`v8-trivy-fix`)

### Mục tiêu học tập
- Áp dụng Docker best practices
- Multi-stage builds và lý do tại sao
- Non-root users trong containers
- Pinned versions vs floating tags

### Những thay đổi cần giải thích chi tiết

#### 1. Multi-stage build
```dockerfile
FROM node:22.17-alpine AS builder  # Stage 1: cài deps
...
FROM node:22.17-alpine AS production  # Stage 2: chỉ copy những gì cần
```
→ Image production nhỏ hơn, không có dev tools, attack surface nhỏ hơn

#### 2. Non-root user
```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```
→ Nếu container bị compromised, attacker chỉ có user-level permissions

#### 3. Pinned version
```dockerfile
FROM node:22.17-alpine  # thay vì node:latest
```
→ Reproducible builds, không bị surprise khi base image update

#### 4. HEALTHCHECK
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1
```
→ Orchestrator (Kubernetes, Docker Swarm) biết container có healthy không

#### 5. npm ci vs npm install
```dockerfile
RUN npm ci --only=production
```
→ `npm ci` = deterministic, faster, dùng lockfile; `--only=production` = no devDeps

### So sánh image size
```bash
# Image cũ (FROM node:latest, single stage)
docker build -f scripts/stages/v0-start/Dockerfile -t old .
docker images old  # ~1.1GB

# Image mới (multi-stage, alpine, non-root)
docker build -t new .
docker images new  # ~150MB
```

### Thảo luận
- Tại sao alpine thay vì debian/ubuntu?
- Sự khác biệt giữa `RUN adduser` và `USER existing-user`?
- Khi nào vẫn cần chạy root trong container? (binding port < 1024)

---

## Bài 9 — Phát Hiện Secret Bị Lộ với Gitleaks (`v9-gitleaks-fail`)

### Mục tiêu học tập
- Hiểu tại sao hardcoded secrets là vấn đề nghiêm trọng
- Gitleaks hoạt động như thế nào
- Cấu hình custom rules trong `.gitleaks.toml`
- Git history và secret exposure

### Kết quả pipeline dự kiến
```
❌ PIPELINE FAIL
  ...
  ❌ Run Gitleaks secret scan
    Finding: hardcoded-api-key — src/config.js:9
    Secret: sk-training-hardcoded-key-do-not-use-in-prod
```

### Điều quan trọng để nói với học viên

**Bài học quan trọng nhất của cả khoá:**

> Khi bạn commit một secret lên git, secret đó **tồn tại mãi mãi trong git history** — dù bạn xoá nó ở commit tiếp theo.  
> Attacker có thể dùng `git log -p` để tìm thấy secret đã xoá.  
> **Giải pháp duy nhất**: rotate (đổi) secret ngay lập tức và coi như đã bị lộ.

### Demo cho học viên thấy
```bash
# Checkout v10 (đã xoá secret)
git checkout v10-gitleaks-fix
cat src/config.js  # Không thấy secret

# Nhưng secret vẫn còn trong history!
git log --all -p -- src/config.js | grep "sk-training"
# → Vẫn thấy secret trong commit v9!
```

### Thảo luận
- `.env` files và `.gitignore` — tại sao không đủ?
- Secret managers: HashiCorp Vault, AWS Secrets Manager, GitHub Secrets
- Pre-commit hooks để prevent secrets từ đầu
- Tại sao `fetch-depth: 0` quan trọng cho Gitleaks?

---

## Bài 10 — Sửa Lỗi Secret (`v10-gitleaks-fix`)

### Mục tiêu học tập
- Pattern đúng để quản lý configuration
- 12-factor app methodology (config qua environment)
- Biết xử lý khi secret đã bị lộ

### Thay đổi cần giải thích
```javascript
// TRƯỚC (BUG):
apiKey: 'sk-training-hardcoded-key-do-not-use-in-prod'

// SAU (FIX):
apiKey: process.env.API_KEY || ''
```

### Cung cấp secret cho ứng dụng trong production
```bash
# Local development
API_KEY=your-dev-key npm start

# Docker
docker run -e API_KEY=your-dev-key ci-training-lab

# GitHub Actions
# Tạo secret: Settings → Secrets → Actions → New secret
# Dùng: ${{ secrets.API_KEY }}

# Kubernetes
kubectl create secret generic app-secrets --from-literal=API_KEY=your-key
```

### Thảo luận
- Tại sao vẫn cần rotate secret dù đã "fix"? (còn trong git history)
- `gitleaks protect --staged` như pre-commit hook
- Cấu hình allowlist trong `.gitleaks.toml` cho false positives

---

## Bài 11 — Push Image lên GHCR (`v11-ghcr`)

### Mục tiêu học tập
- Hiểu Container Registries là gì
- Xác thực với GHCR bằng GITHUB_TOKEN
- Naming conventions cho Docker images
- `push: ${{ github.event_name != 'pull_request' }}` pattern

### Không cần cấu hình thêm
GITHUB_TOKEN có sẵn trong mọi GitHub Actions workflow. Chỉ cần thêm permission:
```yaml
permissions:
  packages: write
```

### Image URL format
```
ghcr.io/OWNER/REPO:TAG
# Ví dụ:
ghcr.io/viettq/ci-training-lab:abc1234
ghcr.io/viettq/ci-training-lab:latest
```

### Pull image sau khi push
```bash
docker pull ghcr.io/viettq/ci-training-lab:latest
docker run -p 3000:3000 ghcr.io/viettq/ci-training-lab:latest
```

### Thảo luận
- Sự khác biệt giữa GHCR, Docker Hub, ECR, GCR
- Image visibility: public vs private packages
- Tại sao tag `latest` có thể là anti-pattern trong production?
- Immutable tags: tại sao dùng SHA thay vì overwrite version tag?

---

## Bài 12 — Parallel Jobs & Reusable Workflow (`v12-reusable-workflow`)

### Mục tiêu học tập
- Thiết kế pipeline với nhiều jobs chạy song song
- Tạo và sử dụng reusable workflows
- `needs` keyword để kiểm soát dependencies
- `workflow_call` trigger

### Parallel execution
```
v11 (single job, sequential):
checkout → test → lint → scan → docker → push
Total time: ~5 min

v12 (parallel jobs):
┌── unit-test (2 min) ──┐
├── lint (1 min) ────────┤→ docker-push (1 min)
├── security-scan (3 min)┤   (after ALL pass)
└── docker-build (2 min)─┘
Total time: ~4 min (vì chạy song song)
```

### Reusable workflow (`workflow_call`)
```yaml
# Caller (ci.yml):
jobs:
  pipeline:
    uses: ./.github/workflows/reusable-build.yml
    with:
      node-version: '22'
    secrets: inherit

# Reusable (reusable-build.yml):
on:
  workflow_call:
    inputs:
      node-version: { type: string, required: true }
```

### Use cases thực tế
- Chia sẻ pipeline logic giữa nhiều repositories (cần external reusable workflow)
- Micro-service architecture: mỗi service dùng chung 1 build pipeline
- Enforce security scanning trên toàn tổ chức

### Thảo luận
- So sánh reusable workflows với Composite Actions
- Khi nào nên dùng `needs` và khi nào không?
- `secrets: inherit` vs khai báo secrets riêng — tradeoffs?
- Environment protection rules với deployment jobs

---

## Phụ lục: Tổng hợp Pipeline Evolution

```
v1  ──→ checkout + setup + npm ci + test
v3  ──→ + lint
v5  ──→ + cache
v6  ──→ + docker build
v7  ──→ + trivy fs + trivy image
v9  ──→ + gitleaks
v11 ──→ + ghcr login + build-push
v12 ──→ split thành 5 jobs song song + reusable workflow
```

---

## Phụ lục: Câu hỏi thường gặp của học viên

| Câu hỏi | Trả lời |
|---------|---------|
| Pipeline chạy bao lâu? | v1: ~3 phút. v12: ~4 phút (nhưng làm nhiều hơn nhiều) |
| Tốn bao nhiêu GitHub Actions minutes? | Public repos: miễn phí. Private: 2000 min/tháng free tier |
| Có thể chạy self-hosted runner không? | Có, xem docs GitHub Actions self-hosted runners |
| Làm sao debug workflow? | `tmate` action để SSH vào runner, hoặc thêm `echo` statements |
| Gitleaks scan toàn bộ history hay chỉ commit mới? | Với `fetch-depth: 0`: toàn bộ history. Với default: chỉ commit hiện tại |

---

## Tài liệu tham khảo

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Gitleaks Documentation](https://gitleaks.io/)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [OWASP Top 10 CI/CD Security Risks](https://owasp.org/www-project-top-10-ci-cd-security-risks/)
