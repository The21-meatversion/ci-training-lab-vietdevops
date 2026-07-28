# TRAINEE GUIDE — Hướng Dẫn Thực Hành CI/CD

> **Dành cho học viên.** Đọc kỹ từng bước trước khi thực hiện.  
> Bạn **không cần giỏi Git** — guide này giải thích từng lệnh một cách chi tiết.

---

## Mục lục

- [Phần A — Chuẩn bị (làm 1 lần duy nhất)](#phần-a--chuẩn-bị-làm-1-lần-duy-nhất)
- [Phần B — Quy trình làm mỗi bài học](#phần-b--quy-trình-làm-mỗi-bài-học)
- [Phần C — Chi tiết từng bài học](#phần-c--chi-tiết-từng-bài-học)
  - [Bài 0 — Khám phá dự án](#bài-0--khám-phá-dự-án-v0-start)
  - [Bài 1 — Unit Test fail](#bài-1--unit-test-fail-v1-unit-test-fail)
  - [Bài 2 — Xem solution bài 1](#bài-2--xem-solution-bài-1-v2-unit-test-fix)
  - [Bài 3 — Lint fail](#bài-3--lint-fail-v3-lint-fail)
  - [Bài 4 — Xem solution bài 3](#bài-4--xem-solution-bài-3-v4-lint-fix)
  - [Bài 5 — Caching](#bài-5--caching-v5-cache)
  - [Bài 6 — Docker Build](#bài-6--docker-build-trong-ci-v6-docker-build)
  - [Bài 7 — Security Scan fail](#bài-7--security-scan-fail-v7-trivy-fail)
  - [Bài 8 — Xem solution bài 7](#bài-8--xem-solution-bài-7-v8-trivy-fix)
  - [Bài 9 — Secret bị lộ](#bài-9--secret-bị-lộ-v9-gitleaks-fail)
  - [Bài 10 — Xem solution bài 9](#bài-10--xem-solution-bài-9-v10-gitleaks-fix)
  - [Bài 11 — Push lên GHCR](#bài-11--push-image-lên-ghcr-v11-ghcr)
  - [Bài 12 — Reusable Workflow](#bài-12--reusable-workflow-v12-reusable-workflow)
- [Phần D — Git Cheat Sheet](#phần-d--git-cheat-sheet)
- [Phần E — Xử lý lỗi thường gặp](#phần-e--xử-lý-lỗi-thường-gặp)

---

## Phần A — Chuẩn bị (làm 1 lần duy nhất)

### A1. Fork repository về tài khoản GitHub của bạn

> **Fork** nghĩa là tạo một bản sao của repository vào tài khoản GitHub của bạn.  
> Bạn cần có bản sao riêng để CI chạy trên tài khoản của bạn, không ảnh hưởng người khác.

1. Truy cập: `https://github.com/rockman88v/ci-training-lab`
2. Click nút **"Fork"** ở góc trên bên phải
3. Chọn tài khoản của bạn làm **Owner**
4. Click **"Create fork"**
5. Chờ vài giây — GitHub sẽ tạo `https://github.com/<your-username>/ci-training-lab`

---

### A2. Clone repository về máy tính của bạn

> **Clone** nghĩa là tải repository từ GitHub về máy local để làm việc.

```bash
# Thay <your-username> bằng username GitHub của bạn
git clone https://github.com/<your-username>/ci-training-lab.git

# Di chuyển vào thư mục vừa clone
cd ci-training-lab

# Kiểm tra đã vào đúng thư mục chưa
ls
# Bạn sẽ thấy: src/ tests/ .github/ Dockerfile README.md TRAINER_GUIDE.md ...
```

---

### A3. Cài đặt dependencies và chạy thử

```bash
# Cài đặt Node.js dependencies
npm install

# Chạy thử ứng dụng
npm start
# Bạn sẽ thấy: Server running on port 3000

# Mở terminal khác, kiểm tra API
curl http://localhost:3000/health
# Kết quả: {"status":"ok"}

# Dừng server: nhấn Ctrl+C trong terminal đang chạy
```

---

### A4. Kiểm tra các tags hiện có

> **Tag** trong Git là như một "mốc lịch sử" — một snapshot tại một thời điểm cụ thể.  
> Repository này có 13 tags, mỗi tag tương ứng một bài học.

```bash
# Xem danh sách tất cả tags
git tag -l

# Kết quả sẽ là:
# v0-start
# v1-unit-test-fail
# v2-unit-test-fix
# v3-lint-fail
# v4-lint-fix
# v5-cache
# v6-docker-build
# v7-trivy-fail
# v8-trivy-fix
# v9-gitleaks-fail
# v10-gitleaks-fix
# v11-ghcr
# v12-reusable-workflow
```

---

### A5. Cấu hình git (nếu chưa làm)

```bash
# Đặt tên và email (dùng để nhận dạng khi commit)
git config --global user.name "Tên của bạn"
git config --global user.email "email@example.com"
```

---

## Phần B — Quy trình làm mỗi bài học

Mỗi bài học theo đúng quy trình sau. Hãy ghi nhớ pattern này:

```
BƯỚC 1: Checkout tag để quan sát trạng thái lỗi
    ↓
BƯỚC 2: Chạy local để thấy lỗi
    ↓
BƯỚC 3: Đọc workflow file để hiểu CI làm gì
    ↓
BƯỚC 4: Tạo branch mới từ tag đó để sửa
    ↓
BƯỚC 5: Sửa code
    ↓
BƯỚC 6: Test lại local để xác nhận đã sửa
    ↓
BƯỚC 7: Commit và push lên GitHub
    ↓
BƯỚC 8: Vào GitHub xem CI chạy
    ↓
BƯỚC 9: So sánh fix của bạn với solution gốc
    ↓
BƯỚC 10: Bắt đầu bài tiếp theo
```

### Tại sao cần tạo branch thay vì sửa trực tiếp trên tag?

> Tags là **read-only** (chỉ đọc). Bạn **không thể commit** khi đang ở trên một tag.  
> Bạn phải tạo branch mới để có thể commit và push.

---

## Phần C — Chi tiết từng bài học

---

### Bài 0 — Khám phá dự án (`v0-start`)

**Mục tiêu**: Hiểu cấu trúc dự án, chạy thử ứng dụng, nhận ra tại sao cần CI.

#### Bước 1: Checkout tag v0-start

```bash
# Từ main branch, checkout sang tag v0-start
git checkout v0-start
```

Bạn sẽ thấy thông báo như này:
```
Note: switching to 'v0-start'.

You are in 'detached HEAD' state. You can look around, make
experimental changes and commits, but ...
```

> **"detached HEAD"** nghe có vẻ lạ nhưng bình thường. Nghĩa là bạn đang ở trên một tag,
> không ở trên một branch nào. Bạn **chỉ được xem**, không nên commit ở đây.

#### Bước 2: Xem cấu trúc và chạy thử

```bash
# Xem thư mục .github/workflows/
ls .github/workflows/
# Kết quả: KHÔNG có gì (chưa có CI)

# Xem Dockerfile (chú ý những điểm chưa tốt)
cat Dockerfile
# Chú ý: FROM node:latest — đây là điều KHÔNG nên làm trong production

# Cài đặt và chạy ứng dụng
npm install
npm start

# Mở terminal khác để test API
curl http://localhost:3000/health
curl "http://localhost:3000/add?a=5&b=3"
curl "http://localhost:3000/divide?a=10&b=2"

# Nhấn Ctrl+C để dừng server
```

#### Bước 3: Suy nghĩ và thảo luận

- Hiện tại không có CI pipeline nào cả
- Nếu developer push code lỗi lên, làm sao phát hiện?
- Dockerfile dùng `node:latest` — điều gì có thể xảy ra?

#### Bước 4: Kết thúc bài 0, chuẩn bị sang bài 1

```bash
# Không cần sửa gì, chuyển thẳng sang tag bài 1
git checkout v1-unit-test-fail
```

---

### Bài 1 — Unit Test fail (`v1-unit-test-fail`)

**Mục tiêu**: Thấy pipeline fail vì test sai, học cách điều tra và sửa.

#### Bước 1: Checkout tag và xem trạng thái

```bash
git checkout v1-unit-test-fail
```

#### Bước 2: Xem CI workflow vừa được thêm

```bash
# Workflow CI vừa xuất hiện!
cat .github/workflows/ci.yml
```

Bạn sẽ thấy workflow với các bước:
1. Checkout code
2. Setup Node.js
3. Install dependencies (`npm ci`)
4. Run tests (`npm test`)

#### Bước 3: Chạy test local để thấy lỗi

```bash
npm install
npm test
```

Bạn sẽ thấy lỗi như này:
```
FAIL tests/mathService.test.js
  ● mathService - add() › cộng hai số dương

    expect(received).toBe(expected)

    Expected: 4
    Received: 3

      7 |   it('cộng hai số dương', () => {
      8 |     expect(add(1, 2)).toBe(4)  ← SAI: 1+2=3, không phải 4
          ^
```

> Đây là lỗi **cố ý** trong bài học — test mong đợi kết quả sai.

#### Bước 4: Tạo branch để sửa

```bash
# Tạo branch "lesson-01-fix" xuất phát từ tag v1-unit-test-fail
# Đặt tên branch bắt đầu bằng "lesson-XX" để dễ nhận biết
git checkout -b lesson-01-fix
```

Bây giờ bạn đang ở branch `lesson-01-fix`. Bạn có thể sửa và commit bình thường.

#### Bước 5: Tìm và sửa lỗi

```bash
# Mở file test để tìm lỗi
# Dùng editor hoặc lệnh sau để xem
cat tests/mathService.test.js | grep -n "toBe"
```

Mở file `tests/mathService.test.js`, tìm dòng:
```javascript
expect(add(1, 2)).toBe(4)  // SAI
```

Sửa thành:
```javascript
expect(add(1, 2)).toBe(3)  // ĐÚNG: 1 + 2 = 3
```

#### Bước 6: Kiểm tra lại local

```bash
npm test
```

Kết quả mong đợi:
```
PASS tests/mathService.test.js
  ✓ cộng hai số dương
  ✓ ... (tất cả tests đều xanh)

Tests: 11 passed, 11 total
```

#### Bước 7: Commit và push lên GitHub

```bash
# Xem những file đã thay đổi
git status
# Kết quả: modified: tests/mathService.test.js

# Thêm file vào staging
git add tests/mathService.test.js

# Commit với message mô tả
git commit -m "fix: sửa unit test - expect toBe(3) thay vì toBe(4)"

# Push branch lên GitHub (lần đầu cần thêm -u origin)
git push -u origin lesson-01-fix
```

#### Bước 8: Vào GitHub xem CI chạy

1. Mở `https://github.com/<your-username>/ci-training-lab`
2. Click tab **"Actions"**
3. Bạn sẽ thấy một workflow run đang chạy cho branch `lesson-01-fix`
4. Click vào để xem từng step — tất cả phải xanh ✅

> **Nếu thấy CI không chạy**: Kiểm tra tab Actions → Enable Actions nếu bị tắt.

#### Bước 9: So sánh solution của bạn với solution gốc

```bash
# Xem thay đổi trong solution gốc (v2 là bài fix chính thức)
git diff v1-unit-test-fail v2-unit-test-fix
# Bạn sẽ thấy đúng dòng mình vừa sửa
```

#### Bước 10: Chuyển sang bài tiếp theo

```bash
# Quay về main branch trước
git checkout main

# Rồi checkout sang bài tiếp theo
git checkout v3-lint-fail
```

> **Lưu ý**: Branch `lesson-01-fix` vẫn còn trên GitHub của bạn.  
> Không cần xoá, không cần merge — bài học tiếp theo bắt đầu hoàn toàn độc lập.

---

### Bài 2 — Xem solution bài 1 (`v2-unit-test-fix`)

**Mục tiêu**: Quan sát pipeline pass hoàn toàn, hiểu coverage report.

> Bài này **không có lỗi** — bạn chỉ cần checkout và quan sát.

```bash
git checkout v2-unit-test-fix

# Xem file test đã được sửa
cat tests/mathService.test.js

# Chạy test với coverage
npm test -- --coverage

# Mở coverage report trong browser (Linux)
xdg-open coverage/lcov-report/index.html
# Hoặc đơn giản xem tóm tắt trong terminal
```

Quan sát coverage report:
- **Statements**: % dòng code đã được test chạy qua
- **Branches**: % các nhánh if/else đã được test
- **Functions**: % hàm đã được test

Sau đó push một commit nhỏ để xem CI chạy xanh:

```bash
git checkout -b lesson-02-observe
git push -u origin lesson-02-observe
# CI sẽ chạy và xanh toàn bộ — quan sát thời gian từng step
```

Tiếp tục:

```bash
git checkout main
git checkout v3-lint-fail
```

---

### Bài 3 — Lint fail (`v3-lint-fail`)

**Mục tiêu**: Thấy ESLint fail trong CI, học cách đọc và sửa lint errors.

#### Bước 1: Checkout và xem những gì mới

```bash
git checkout v3-lint-fail

# Xem workflow đã được cập nhật (thêm bước lint)
cat .github/workflows/ci.yml
# Chú ý bước "Run ESLint" vừa được thêm vào
```

#### Bước 2: Chạy lint local để thấy lỗi

```bash
npm install
npm run lint
```

Bạn sẽ thấy nhiều lỗi:
```
/path/src/routes/api.js
  8:7   error  'unusedConfig' is assigned a value but never used  no-unused-vars
  4:1   error  Missing semicolon                                   semi

/path/src/services/mathService.js
  3:7   error  'version' is assigned a value but never used       no-unused-vars
  ...

✖ 12 problems (12 errors, 0 warnings)
```

Đọc output của ESLint theo format: `file:line:col errorType 'mô tả'`

#### Bước 3: Tạo branch sửa lỗi

```bash
git checkout -b lesson-03-lint-fix
```

#### Bước 4: Sửa lỗi lint

**Bước 4a — Thử auto-fix trước:**

```bash
npm run lint:fix
# ESLint sẽ tự động sửa được: thiếu semicolons (;)
# KHÔNG tự sửa được: unused variables
```

**Bước 4b — Sửa thủ công unused variables:**

Mở `src/routes/api.js`:
```javascript
// TÌM và XOÁ dòng này (khai báo biến mà không dùng):
const unusedConfig = require('./config')  // ← XOÁ dòng này
```

Mở `src/services/mathService.js`:
```javascript
// TÌM và XOÁ dòng này:
const version = '1.0.0'  // ← XOÁ dòng này
```

**Bước 4c — Kiểm tra lại:**

```bash
npm run lint
# Phải thấy: no errors
```

#### Bước 5: Chạy cả test lẫn lint để đảm bảo không break gì

```bash
npm test
npm run lint
# Cả hai phải xanh
```

#### Bước 6: Commit và push

```bash
git status
# Sẽ thấy: modified: src/routes/api.js, src/services/mathService.js

git add src/routes/api.js src/services/mathService.js
git commit -m "fix: sửa lint errors - xoá unused vars, thêm semicolons"
git push -u origin lesson-03-lint-fix
```

#### Bước 7: Vào GitHub Actions kiểm tra

- Tab **Actions** → xem workflow run cho `lesson-03-lint-fix`
- Cả unit test lẫn lint phải ✅

#### Bước 8: So sánh với solution gốc

```bash
git diff v3-lint-fail v4-lint-fix -- src/
```

#### Bước 9: Sang bài tiếp

```bash
git checkout main
git checkout v5-cache
```

---

### Bài 4 — Xem solution bài 3 (`v4-lint-fix`)

**Mục tiêu**: Xem code sạch sau khi fix lint, thảo luận về code style.

```bash
git checkout v4-lint-fix

# So sánh trực tiếp với bài trước để thấy rõ thay đổi
git diff v3-lint-fail v4-lint-fix -- src/routes/api.js
git diff v3-lint-fail v4-lint-fix -- src/services/mathService.js

# Chạy lint để confirm 0 errors
npm install && npm run lint
```

Sau đó:

```bash
git checkout main
git checkout v5-cache
```

---

### Bài 5 — Caching (`v5-cache`)

**Mục tiêu**: Thấy sự khác biệt về tốc độ pipeline khi có/không có npm cache.

> Bài này **không có lỗi** — bạn quan sát sự thay đổi trong workflow và đo thời gian.

#### Bước 1: Checkout và xem thay đổi

```bash
git checkout v5-cache

# So sánh workflow với bài trước
git diff v4-lint-fix v5-cache -- .github/workflows/ci.yml
```

Bạn sẽ thấy một dòng được thêm vào:
```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '22'
    cache: 'npm'    ← Dòng này là tất cả sự khác biệt
```

#### Bước 2: Push lên để xem cache hoạt động

```bash
git checkout -b lesson-05-cache-test

# Tạo một commit nhỏ để trigger CI
# Sửa comment bất kỳ trong README hoặc thêm dòng trống
echo "" >> README.md
git add README.md
git commit -m "test: trigger CI để quan sát cache"
git push -u origin lesson-05-cache-test
```

#### Bước 3: So sánh thời gian

Vào **GitHub Actions → Actions tab**:
- **Lần chạy 1** (cache miss): Bước "Install dependencies" ~ 40-60 giây
- **Push thêm 1 commit nữa** (cache hit): Bước "Install dependencies" ~ 3-5 giây

```bash
# Push commit thứ 2 để thấy cache hit
echo "# test" >> README.md
git add README.md
git commit -m "test: trigger CI lần 2 để thấy cache hit"
git push
```

Sau đó:

```bash
git checkout main
git checkout v6-docker-build
```

---

### Bài 6 — Docker Build trong CI (`v6-docker-build`)

**Mục tiêu**: Xem CI build Docker image, hiểu tagging strategy.

```bash
git checkout v6-docker-build

# Xem workflow mới
cat .github/workflows/ci.yml
# Chú ý bước docker build với tag ${{ github.sha }}
```

#### Thực hành local

```bash
npm install

# Build Docker image local
docker build -t ci-training-lab:local .

# Xem size image
docker images ci-training-lab

# Chạy container
docker run -d -p 3000:3000 --name ci-test ci-training-lab:local

# Test API
curl http://localhost:3000/health

# Kiểm tra container đang chạy dưới user nào
docker exec ci-test whoami
# Sẽ thấy: root  ← KHÔNG TỐT (sẽ được sửa ở bài 8)

# Dừng và xoá container
docker stop ci-test && docker rm ci-test
```

#### Push lên xem CI

```bash
git checkout -b lesson-06-docker-test
echo "" >> README.md
git add README.md
git commit -m "test: trigger CI để xem docker build"
git push -u origin lesson-06-docker-test
```

Xem trong GitHub Actions — step "Build Docker image" sẽ xuất hiện.

Sau đó:

```bash
git checkout main
git checkout v7-trivy-fail
```

---

### Bài 7 — Security Scan fail (`v7-trivy-fail`)

**Mục tiêu**: Thấy Trivy phát hiện CVE trong dependency, học cách đọc security report.

#### Bước 1: Checkout và quan sát

```bash
git checkout v7-trivy-fail

# Xem thay đổi trong package.json (lodash bị downgrade)
cat package.json | grep lodash
# Kết quả: "lodash": "4.17.4"  ← phiên bản CŨ có lỗ hổng

# Xem workflow — Trivy được thêm vào
cat .github/workflows/ci.yml
```

#### Bước 2: Kiểm tra CVE local (nếu có Trivy)

```bash
# Nếu đã cài Trivy:
trivy fs --severity CRITICAL,HIGH .
# Sẽ thấy: CVE-2019-10744 trong lodash@4.17.4 — Prototype Pollution — CRITICAL
```

Nếu chưa có Trivy, push lên GitHub để thấy CI fail.

#### Bước 3: Tạo branch sửa lỗi

```bash
git checkout -b lesson-07-security-fix
```

#### Bước 4: Sửa lỗi bảo mật

Mở `package.json`, tìm và sửa:
```json
// TRƯỚC:
"lodash": "4.17.4"

// SAU:
"lodash": "^4.17.21"
```

**Giải thích**:
- `4.17.4` — phiên bản cũ, có CVE
- `^4.17.21` — cho phép dùng 4.17.21 trở lên (trong phạm vi 4.x.x)

#### Bước 5: Cập nhật package-lock.json

```bash
# Xoá node_modules và cài lại để cập nhật lock file
rm -rf node_modules
npm install

# Kiểm tra lodash version đã được nâng lên
cat package-lock.json | grep '"lodash"' | head -5
# Phải thấy phiên bản >= 4.17.21
```

#### Bước 6: Commit và push

```bash
git add package.json package-lock.json
git commit -m "fix: nâng cấp lodash 4.17.4 → 4.17.21 để fix CVE-2019-10744"
git push -u origin lesson-07-security-fix
```

#### Bước 7: Xem CI

Vào GitHub Actions — CI sẽ:
- ✅ Unit tests pass
- ✅ Lint pass
- ✅ Trivy scan: không còn CRITICAL CVE

> **Lưu ý**: Trivy cũng quét Dockerfile và có thể vẫn báo lỗi về base image `node:latest`.  
> Dockerfile sẽ được sửa đúng ở bài 8.

Sau đó:

```bash
git checkout main
git checkout v8-trivy-fix
```

---

### Bài 8 — Xem solution bài 7 (`v8-trivy-fix`)

**Mục tiêu**: Xem Dockerfile chuẩn production, hiểu multi-stage build và non-root user.

```bash
git checkout v8-trivy-fix

# Xem Dockerfile đã được cải thiện hoàn toàn
cat Dockerfile
```

Những thay đổi quan trọng trong Dockerfile:
```dockerfile
# 1. Base image được pin version (không dùng :latest)
FROM node:22.17-alpine AS builder

# 2. Multi-stage build — image production nhỏ hơn
FROM node:22.17-alpine AS production

# 3. Non-root user — bảo mật hơn
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 4. HEALTHCHECK — container tự báo cáo trạng thái sức khoẻ
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1
```

#### So sánh image size

```bash
# Build image cũ (v6)
git stash  # bỏ qua nếu gặp lỗi
docker build -t ci-lab:old -f <(git show v6-docker-build:Dockerfile) .

# Build image mới (v8)
docker build -t ci-lab:new .

# So sánh size
docker images | grep ci-lab
```

#### Kiểm tra container chạy dưới user nào

```bash
docker run --rm ci-lab:new whoami
# Phải thấy: appuser (không phải root)
```

Sau đó:

```bash
git checkout main
git checkout v9-gitleaks-fail
```

---

### Bài 9 — Secret bị lộ (`v9-gitleaks-fail`)

**Mục tiêu**: Thấy Gitleaks phát hiện hardcoded secret trong code, hiểu tại sao KHÔNG ĐƯỢC commit secrets.

#### Bước 1: Checkout và tìm secret bị lộ

```bash
git checkout v9-gitleaks-fail

# Xem config.js — tìm điểm khác biệt
cat src/config.js
```

Bạn sẽ thấy:
```javascript
apiKey: 'sk-training-hardcoded-key-do-not-use-in-prod'
// ↑ ĐÂY LÀ SECRET BỊ HARDCODE TRONG CODE — cực kỳ nguy hiểm
```

#### Bước 2: Xem workflow thêm Gitleaks

```bash
cat .github/workflows/ci.yml
# Chú ý: fetch-depth: 0  ← Gitleaks cần TOÀN BỘ git history
# Chú ý: gitleaks/gitleaks-action vừa được thêm vào
```

#### Bước 3: Tạo branch sửa lỗi

```bash
git checkout -b lesson-09-fix-secret
```

#### Bước 4: Sửa — xoá hardcoded secret, dùng environment variable

Mở `src/config.js`, sửa:
```javascript
// TRƯỚC (NGUY HIỂM):
apiKey: 'sk-training-hardcoded-key-do-not-use-in-prod'

// SAU (AN TOÀN):
apiKey: process.env.API_KEY || ''
```

Sau khi sửa, thêm đoạn cảnh báo nếu API_KEY không được set:
```javascript
if (!config.apiKey && process.env.NODE_ENV !== 'test') {
  console.warn('WARNING: API_KEY is not set')
}
```

#### Bước 5: Kiểm tra lại

```bash
npm test   # phải pass
npm run lint  # phải không có lỗi
```

#### Bước 6: Commit và push

```bash
git add src/config.js
git commit -m "fix: xoá hardcoded API key, dùng environment variable"
git push -u origin lesson-09-fix-secret
```

#### Bước 7: Xem CI trên GitHub

Vào Actions — Gitleaks step phải ✅

#### Bài học quan trọng

> **KHÔNG BAO GIỜ commit secrets vào Git!**  
> Dù bạn có xoá ở commit sau, secret vẫn còn trong git history và có thể bị tìm thấy.  
> Secret đã lên GitHub = coi như đã bị lộ → phải revoke và tạo secret mới ngay lập tức.

Sau đó:

```bash
git checkout main
git checkout v10-gitleaks-fix
```

---

### Bài 10 — Xem solution bài 9 (`v10-gitleaks-fix`)

**Mục tiêu**: Xem cách đúng để quản lý secrets trong ứng dụng.

```bash
git checkout v10-gitleaks-fix

# So sánh với bài trước
git diff v9-gitleaks-fail v10-gitleaks-fix -- src/config.js
```

#### Cách dùng secret trên GitHub Actions

1. Vào repo GitHub → **Settings** → **Secrets and variables** → **Actions**
2. Click **"New repository secret"**
3. Nhập `API_KEY` và giá trị

Trong workflow, dùng secret:
```yaml
env:
  API_KEY: ${{ secrets.API_KEY }}
```

Sau đó:

```bash
git checkout main
git checkout v11-ghcr
```

---

### Bài 11 — Push image lên GHCR (`v11-ghcr`)

**Mục tiêu**: Xem cách push Docker image lên GitHub Container Registry.

```bash
git checkout v11-ghcr

# Xem thay đổi trong workflow — phần docker push mới
git diff v10-gitleaks-fix v11-ghcr -- .github/workflows/ci.yml
```

Workflow mới có:
```yaml
- uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}  # Tự động, không cần cấu hình thêm

- uses: docker/build-push-action@v5
  with:
    push: true
    tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
```

#### Push lên để xem image được publish

```bash
git checkout -b lesson-11-ghcr-test
echo "" >> README.md
git add README.md
git commit -m "test: trigger GHCR push"
git push -u origin lesson-11-ghcr-test
```

Sau khi CI chạy xong:
1. Vào `https://github.com/<your-username>?tab=packages`
2. Bạn sẽ thấy package `ci-training-lab` đã được push

> **Lưu ý**: Image chỉ được push khi push lên branch (không push khi là Pull Request).

Sau đó:

```bash
git checkout main
git checkout v12-reusable-workflow
```

---

### Bài 12 — Reusable Workflow (`v12-reusable-workflow`)

**Mục tiêu**: Hiểu reusable workflows, parallel jobs, và sự khác biệt với workflow trước đó.

```bash
git checkout v12-reusable-workflow

# Xem hai workflow files
cat .github/workflows/ci.yml            # Caller workflow (ngắn gọn)
cat .github/workflows/reusable-build.yml # Reusable workflow (5 jobs song song)
```

#### Phân tích cấu trúc

**ci.yml** (caller) — chỉ cần gọi workflow khác:
```yaml
jobs:
  build:
    uses: ./.github/workflows/reusable-build.yml
    with:
      node-version: '22'
      image-name: ${{ github.repository }}
    secrets: inherit
```

**reusable-build.yml** — 5 jobs chạy song song:
```
unit-test  ─────────────────┐
lint       ─────────────────┤
security-scan ──────────────┤→ docker-push (chờ tất cả pass)
docker-build ───────────────┘
```

#### So sánh với bài trước

```bash
# Xem timeline: các jobs chạy song song (parallel) thay vì tuần tự (sequential)
# Trong GitHub Actions → chọn run → xem visualization
```

#### Push để xem parallel jobs

```bash
git checkout -b lesson-12-final
echo "" >> README.md
git add README.md
git commit -m "test: trigger reusable workflow để xem parallel jobs"
git push -u origin lesson-12-final
```

Vào **GitHub Actions** → click vào run mới nhất → bạn sẽ thấy 5 jobs chạy đồng thời!

---

## Phần D — Git Cheat Sheet

Bảng tổng hợp các lệnh Git cần dùng trong khoá học:

### Xem thông tin

```bash
# Xem đang ở branch/tag nào
git status

# Xem danh sách branches
git branch

# Xem tất cả tags
git tag -l

# Xem lịch sử commit (tóm tắt)
git log --oneline --graph

# Xem sự khác biệt giữa hai tags
git diff v1-unit-test-fail v2-unit-test-fix
git diff v1-unit-test-fail v2-unit-test-fix -- tests/mathService.test.js  # chỉ 1 file
```

### Di chuyển giữa các tag/branch

```bash
# Checkout một tag (chỉ xem, không sửa)
git checkout v3-lint-fail

# Tạo branch MỚI từ vị trí hiện tại (để sửa code)
git checkout -b lesson-03-lint-fix

# Quay về main branch
git checkout main

# Chuyển sang branch đã tạo trước đó
git checkout lesson-01-fix
```

### Làm việc với thay đổi

```bash
# Xem file nào đã thay đổi
git status

# Xem nội dung thay đổi chi tiết
git diff

# Thêm file vào staging (chuẩn bị commit)
git add <tên-file>
git add .                    # thêm TẤT CẢ file thay đổi

# Commit (lưu thay đổi vào lịch sử local)
git commit -m "mô tả thay đổi"

# Push lên GitHub
git push -u origin <tên-branch>    # lần đầu tiên (tạo branch trên remote)
git push                           # lần sau (đã có branch trên remote)
```

### Bỏ thay đổi (undo)

```bash
# Bỏ thay đổi chưa được add (restore file về trạng thái gốc)
git restore <tên-file>

# Bỏ tất cả thay đổi chưa được add
git restore .

# Bỏ thay đổi đã được add (unstage)
git restore --staged <tên-file>
```

### Sơ đồ quy trình commit

```
[Sửa code]
    ↓
git add <file>      ← thêm vào "staging area"
    ↓
git commit -m "..."  ← lưu vào lịch sử local
    ↓
git push            ← đồng bộ lên GitHub → CI trigger
```

---

## Phần E — Xử lý lỗi thường gặp

### Lỗi: "You are in 'detached HEAD' state"

```
You are in 'detached HEAD' state.
```

**Giải thích**: Bạn vừa checkout một tag. Đây là bình thường và không nguy hiểm.  
**Xử lý**: Nếu muốn sửa code, tạo branch mới:

```bash
git checkout -b lesson-XX-ten-ban
```

---

### Lỗi: "fatal: not a git repository"

```
fatal: not a git repository (or any of the parent directories): .git
```

**Nguyên nhân**: Bạn đang ở sai thư mục.  
**Xử lý**:

```bash
# Kiểm tra thư mục hiện tại
pwd

# Di chuyển vào thư mục đúng
cd /đường/dẫn/đến/ci-training-lab
```

---

### Lỗi: "error: Your local changes would be overwritten by checkout"

```
error: Your local changes to the following files would be overwritten by checkout
```

**Nguyên nhân**: Bạn có thay đổi chưa commit, và bạn muốn checkout sang tag/branch khác.  
**Xử lý** (chọn một):

```bash
# Option 1: Lưu thay đổi tạm thời (stash)
git stash         # lưu thay đổi
git checkout ...  # checkout bình thường
git stash pop     # lấy lại thay đổi sau (nếu cần)

# Option 2: Bỏ thay đổi (nếu không cần giữ)
git restore .     # bỏ tất cả thay đổi chưa add
git checkout ...  # checkout bình thường
```

---

### Lỗi: "! [rejected] — non-fast-forward"

```
! [rejected]   lesson-01-fix -> lesson-01-fix (non-fast-forward)
```

**Nguyên nhân**: Remote có commit mà local chưa có (ví dụ GitHub Actions tự commit).  
**Xử lý**:

```bash
git pull origin lesson-01-fix  # kéo thay đổi từ remote về
git push                        # push lại
```

---

### CI không chạy sau khi push

**Kiểm tra**:

1. Vào GitHub repo → tab **Actions**
2. Nếu thấy thông báo "Actions are disabled" → click "Enable Actions"
3. Nếu Actions đã bật mà không có run mới → xem workflow trigger có đúng không:

```bash
cat .github/workflows/ci.yml | head -10
# Phải có:
# on:
#   push:
#     branches: ['**']
```

---

### Lỗi npm test: "Cannot find module"

```
Cannot find module '../src/mathService'
```

**Nguyên nhân**: Chưa chạy `npm install` sau khi checkout tag mới.  
**Xử lý**:

```bash
npm install
npm test
```

---

### Port 3000 đã bị dùng

```
Error: listen EADDRINUSE: address already in use :::3000
```

**Xử lý**:

```bash
# Option 1: Tìm và kill process đang dùng port 3000
lsof -i :3000
kill -9 <PID>

# Option 2: Dùng port khác
PORT=3001 npm start
```

---

## Tổng kết quy trình học tập

```
Bài lỗi (v1, v3, v7, v9):
  1. git checkout <tag-lỗi>          → quan sát lỗi
  2. npm test / npm run lint          → thấy lỗi local
  3. git checkout -b lesson-XX-fix    → tạo branch sửa
  4. [sửa code]
  5. npm test / npm run lint          → verify đã sửa
  6. git add . && git commit -m "..." → commit
  7. git push -u origin lesson-XX-fix → push lên GitHub
  8. Vào GitHub Actions xem CI xanh   → xác nhận
  9. git diff <tag-lỗi> <tag-fix>     → học từ solution gốc
 10. git checkout main                → chuẩn bị bài tiếp

Bài quan sát (v0, v2, v4, v5, v6, v8, v10, v11, v12):
  1. git checkout <tag>               → xem code
  2. [đọc, chạy, so sánh]
  3. git checkout main                → sang bài tiếp
```

---

> **Lời khuyên cuối**: Đừng sợ mắc lỗi với Git. Mọi thao tác trong khoá học này đều an toàn.  
> Branch và commit có thể xoá dễ dàng. Thực hành nhiều sẽ giúp bạn tự tin hơn.
