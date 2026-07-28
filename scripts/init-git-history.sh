#!/usr/bin/env bash
# =============================================================================
# init-git-history.sh
# Khởi tạo git history hoàn chỉnh cho CI Training Lab
#
# Cách dùng:
#   bash scripts/init-git-history.sh
#
# Yêu cầu:
#   - git đã được cài đặt
#   - node và npm đã được cài đặt (để tạo package-lock.json)
#   - Chạy từ thư mục gốc của repository
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Cấu hình
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/stages" && pwd)"

# Màu sắc cho terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ---------------------------------------------------------------------------
# Hàm tiện ích
# ---------------------------------------------------------------------------
log_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error()   { echo -e "${RED}❌ $1${NC}"; }

# Kiểm tra yêu cầu
check_requirements() {
  log_info "Kiểm tra yêu cầu hệ thống..."
  for cmd in git node npm; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "Lệnh '$cmd' không tìm thấy. Vui lòng cài đặt trước."
      exit 1
    fi
  done
  log_success "Tất cả yêu cầu đã sẵn sàng."
}

# ---------------------------------------------------------------------------
# Kiểm tra an toàn
# ---------------------------------------------------------------------------
safety_check() {
  cd "$REPO_ROOT"
  if [ -d ".git" ]; then
    log_warn "Git repository đã tồn tại tại: $REPO_ROOT"
    echo -e "${YELLOW}Tiếp tục sẽ XOÁ toàn bộ git history hiện tại!${NC}"
    read -r -p "Bạn có chắc chắn muốn khởi tạo lại? (yes/N): " confirm
    if [ "$confirm" != "yes" ]; then
      log_info "Huỷ bỏ. Không có thay đổi nào được thực hiện."
      exit 0
    fi
    rm -rf .git
    log_warn "Đã xoá git history cũ."
  fi
}

# ---------------------------------------------------------------------------
# Hàm áp dụng một stage và tạo commit + tag
# ---------------------------------------------------------------------------
# Tham số:
#   $1 - tên stage (thư mục trong scripts/stages/)
#   $2 - commit message
#   $3 - tên tag git
#   $4 - (tùy chọn) "npm" nếu cần chạy npm install sau khi copy
# ---------------------------------------------------------------------------
apply_stage() {
  local stage_name="$1"
  local commit_msg="$2"
  local tag_name="$3"
  local run_npm="${4:-}"
  local stage_dir="$STAGES_DIR/$stage_name"

  log_info "Áp dụng stage: ${YELLOW}$tag_name${NC}"

  if [ ! -d "$stage_dir" ]; then
    log_error "Không tìm thấy thư mục stage: $stage_dir"
    exit 1
  fi

  # Copy files từ stage directory vào repo root
  cp -r "$stage_dir/." "$REPO_ROOT/"

  # Nếu cần tạo/cập nhật package-lock.json
  if [ "$run_npm" = "npm" ]; then
    log_info "Cập nhật package-lock.json..."
    cd "$REPO_ROOT"
    npm install --package-lock-only --silent 2>/dev/null || npm install --silent
  fi

  # Lấy danh sách files từ stage directory để git add đúng files
  local files_to_add=()
  while IFS= read -r -d '' file; do
    local rel_path="${file#$stage_dir/}"
    files_to_add+=("$rel_path")
  done < <(find "$stage_dir" -type f -print0)

  # Thêm package-lock.json nếu vừa chạy npm
  if [ "$run_npm" = "npm" ] && [ -f "$REPO_ROOT/package-lock.json" ]; then
    files_to_add+=("package-lock.json")
  fi

  cd "$REPO_ROOT"
  git add "${files_to_add[@]}"
  git commit -m "$commit_msg"
  git tag "$tag_name"

  log_success "Tagged: ${GREEN}$tag_name${NC}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║        CI Training Lab - Git History Builder             ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  check_requirements
  safety_check

  cd "$REPO_ROOT"

  # ---------------------------------------------------------------------------
  # Khởi tạo git repository
  # ---------------------------------------------------------------------------
  log_info "Khởi tạo git repository..."
  git init
  git checkout -b main 2>/dev/null || git branch -m main
  git config user.email "trainer@ci-training-lab.com"
  git config user.name "CI Training Lab"
  log_success "Git repository đã được khởi tạo."
  echo ""

  # ---------------------------------------------------------------------------
  # Stage v0: Khởi tạo dự án
  # ---------------------------------------------------------------------------
  apply_stage \
    "v0-start" \
    "chore: initial project setup with Express REST API

- Create Express.js REST API with /health, /add, /divide endpoints
- Add mathService with add() and divide() functions
- Setup package.json with express and lodash dependencies
- Add jest.config.js and .gitignore
- Add initial Dockerfile (needs improvement)
- Add training scripts and documentation" \
    "v0-start" \
    "npm"

  # Thêm scripts/ directory (meta files for training) và di chuyển tag
  git tag -d v0-start
  git add scripts/
  git commit --amend --no-edit --no-verify 2>/dev/null || true
  git tag v0-start

  # ---------------------------------------------------------------------------
  # Stage v1: Thêm CI workflow (test sẽ FAIL)
  # ---------------------------------------------------------------------------
  apply_stage \
    "v1-unit-test-fail" \
    "ci: add GitHub Actions workflow with unit tests

- Add .github/workflows/ci.yml with checkout, setup-node, npm ci, npm test
- Add tests/mathService.test.js with unit tests
- BUG: test expects add(1,2) === 4 (should be 3) — pipeline will FAIL" \
    "v1-unit-test-fail"

  # ---------------------------------------------------------------------------
  # Stage v2: Sửa unit test
  # ---------------------------------------------------------------------------
  apply_stage \
    "v2-unit-test-fix" \
    "fix: correct expected value in add() unit test

- Fix: expect(add(1, 2)).toBe(3) — was incorrectly set to 4
- Add additional test cases for better coverage
- Pipeline should now PASS" \
    "v2-unit-test-fix"

  # ---------------------------------------------------------------------------
  # Stage v3: Thêm ESLint (sẽ FAIL vì có lint errors)
  # ---------------------------------------------------------------------------
  apply_stage \
    "v3-lint-fail" \
    "ci: add ESLint to pipeline

- Add .eslintrc.js with strict rules (semi, no-unused-vars, eqeqeq)
- Add npm run lint step to ci.yml
- BUG: source files have lint errors (missing semicolons, unused variables)
- Pipeline will FAIL at lint step" \
    "v3-lint-fail"

  # ---------------------------------------------------------------------------
  # Stage v4: Sửa lint errors
  # ---------------------------------------------------------------------------
  apply_stage \
    "v4-lint-fix" \
    "fix: resolve all ESLint errors in source files

- Add missing semicolons to routes/api.js and services/mathService.js
- Remove unused variables (unusedConfig, version)
- All lint rules now pass" \
    "v4-lint-fix"

  # ---------------------------------------------------------------------------
  # Stage v5: Thêm npm cache
  # ---------------------------------------------------------------------------
  apply_stage \
    "v5-cache" \
    "perf: enable npm dependency caching in CI

- Add cache: 'npm' to actions/setup-node step
- Reduces pipeline execution time on subsequent runs
- Cache key is based on package-lock.json hash" \
    "v5-cache"

  # ---------------------------------------------------------------------------
  # Stage v6: Thêm Docker build
  # ---------------------------------------------------------------------------
  apply_stage \
    "v6-docker-build" \
    "feat: add Docker image build step to CI pipeline

- Add 'docker build' step after lint
- Image tagged with git SHA for traceability
- Dockerfile uses node:latest (will be improved later)" \
    "v6-docker-build"

  # ---------------------------------------------------------------------------
  # Stage v7: Thêm Trivy scan (sẽ FAIL vì có vulnerabilities)
  # ---------------------------------------------------------------------------
  apply_stage \
    "v7-trivy-fail" \
    "ci: add Trivy security scanning to pipeline

- Add filesystem scan with Trivy (scans npm dependencies)
- Add Docker image scan with Trivy
- Downgrade lodash to 4.17.4 (CVE-2019-10744 prototype pollution)
- BUG: pipeline will FAIL due to vulnerable lodash and insecure Dockerfile" \
    "v7-trivy-fail" \
    "npm"

  # ---------------------------------------------------------------------------
  # Stage v8: Sửa security issues
  # ---------------------------------------------------------------------------
  apply_stage \
    "v8-trivy-fix" \
    "fix: resolve security vulnerabilities found by Trivy

- Upgrade lodash from 4.17.4 to ^4.17.21 (fixes CVE-2019-10744)
- Rewrite Dockerfile with security best practices:
  * Use pinned version node:22.17-alpine instead of latest
  * Add multi-stage build to separate builder from production
  * Run as non-root user (appuser)
  * Use npm ci --only=production
  * Add HEALTHCHECK instruction
- Add .dockerignore to prevent sensitive files from being copied" \
    "v8-trivy-fix" \
    "npm"

  # ---------------------------------------------------------------------------
  # Stage v9: Thêm Gitleaks (sẽ FAIL vì có hardcoded secret)
  # ---------------------------------------------------------------------------
  apply_stage \
    "v9-gitleaks-fail" \
    "ci: add Gitleaks secret scanning and config module

- Add .gitleaks.toml with custom API key detection rule
- Add gitleaks/gitleaks-action@v2 to CI pipeline
- Add src/config.js module for app configuration
- BUG: config.js contains hardcoded API key — Gitleaks will detect it
- Pipeline will FAIL at secret scan step" \
    "v9-gitleaks-fail"

  # ---------------------------------------------------------------------------
  # Stage v10: Sửa hardcoded secret
  # ---------------------------------------------------------------------------
  apply_stage \
    "v10-gitleaks-fix" \
    "fix: remove hardcoded API key, use environment variable

- Remove hardcoded apiKey from src/config.js
- Read API_KEY from process.env.API_KEY instead
- Add warning log when API_KEY is not set in non-test environments
- Gitleaks scan should now PASS" \
    "v10-gitleaks-fix"

  # ---------------------------------------------------------------------------
  # Stage v11: Push image lên GHCR
  # ---------------------------------------------------------------------------
  apply_stage \
    "v11-ghcr" \
    "feat: push Docker image to GitHub Container Registry (GHCR)

- Add docker/login-action@v3 to authenticate with GHCR
- Replace manual docker build with docker/build-push-action@v5
- Push image to ghcr.io/\${{ github.repository }} on main branch pushes
- Skip push on pull requests (build only for verification)
- Uses GITHUB_TOKEN for authentication (no extra secrets needed)" \
    "v11-ghcr"

  # ---------------------------------------------------------------------------
  # Stage v12: Refactor thành reusable workflow
  # ---------------------------------------------------------------------------
  apply_stage \
    "v12-reusable-workflow" \
    "refactor: split pipeline into parallel jobs with reusable workflow

- Create .github/workflows/reusable-build.yml with 5 independent jobs:
  * unit-test: runs jest tests
  * lint: runs eslint
  * security-scan: runs gitleaks + trivy fs
  * docker-build: builds image + trivy image scan
  * docker-push: pushes to GHCR (needs all 4 jobs to pass first)
- Refactor ci.yml to call reusable workflow via workflow_call
- Jobs unit-test, lint, security-scan, docker-build run in PARALLEL
- Demonstrates: reusability, parallel execution, separation of concerns" \
    "v12-reusable-workflow"

  # ---------------------------------------------------------------------------
  # Hoàn thành
  # ---------------------------------------------------------------------------
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║              Git History Đã Được Tạo Thành Công!        ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""
  log_info "Tổng quan git tags:"
  git tag -l | while read -r tag; do
    echo -e "  ${GREEN}▶${NC} $tag"
  done
  echo ""
  log_info "Git log (tóm tắt):"
  git log --oneline --decorate | head -20
  echo ""
  log_success "Repository sẵn sàng cho đào tạo!"
  echo ""
  echo -e "${YELLOW}Hướng dẫn tiếp theo:${NC}"
  echo "  1. Tạo repository mới trên GitHub"
  echo "  2. git remote add origin <url>"
  echo "  3. git push --all && git push --tags"
  echo "  4. Chia sẻ repository URL với học viên"
  echo ""
}

main "$@"
