# =============================================================================
# Stage 1: Builder — cài đặt dependencies production
# =============================================================================
FROM node:22.17-alpine AS builder

WORKDIR /app

# ✅ Copy package files TRƯỚC để Docker cache layer này khi code thay đổi
COPY package*.json ./

# ✅ npm ci thay vì npm install — đảm bảo version nhất quán với lock file
# ✅ --only=production — không cài dev dependencies vào production image
# ✅ npm cache clean — giảm kích thước image
RUN npm ci --only=production && npm cache clean --force

# =============================================================================
# Stage 2: Production — image tối thiểu, chạy non-root
# =============================================================================
FROM node:22.19-alpine AS production

RUN apk update && apk upgrade --no-cache && rm -rf /var/cache/apk/*


# ✅ Tạo user và group không có quyền root — nguyên tắc least privilege
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# ✅ Chỉ copy production node_modules từ builder — không có dev deps
COPY --from=builder /app/node_modules ./node_modules

# ✅ Chỉ copy source code cần thiết
COPY src/ ./src/

# ✅ Chuyển sang non-root user
USER appuser

EXPOSE 3000

# ✅ Health check — cho phép orchestrator biết container có healthy không
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/app.js"]
