# Docker Best Practices — Từ Bad đến Good

## So sánh: Dockerfile cũ vs mới

| Tiêu chí | v0 (Bad) | v8 (Good) |
|----------|----------|-----------|
| Base image | `node:latest` | `node:22.17-alpine` |
| User | root | appuser (non-root) |
| Stages | Single | Multi-stage |
| Dependencies | npm install (all) | npm ci --only=production |
| Cache | Poor (COPY . . first) | Good (package*.json first) |
| Image size | ~1.1 GB | ~150 MB |
| Health check | None | wget /health |
| .dockerignore | None | Yes |

---

## Multi-stage Build Flow

```mermaid
graph TD
    subgraph Stage1 ["Stage 1: Builder (node:22.17-alpine)"]
        B1[COPY package*.json ./]
        B2[RUN npm ci --only=production]
        B3[npm cache clean --force]
        B1 --> B2 --> B3
    end

    subgraph Stage2 ["Stage 2: Production (node:22.17-alpine)"]
        P1[RUN addgroup/adduser]
        P2["COPY --from=builder node_modules"]
        P3[COPY src/]
        P4[USER appuser]
        P5[HEALTHCHECK]
        P6[CMD node src/app.js]
        P1 --> P2 --> P3 --> P4 --> P5 --> P6
    end

    Stage1 -->|only node_modules| Stage2
    
    subgraph "NOT in production image"
        X1[dev dependencies]
        X2[test files]
        X3[build tools]
        X4[npm cache]
    end

    B2 -.->|excluded| X1
    B3 -.->|cleaned| X4

    style Stage1 fill:#E3F2FD
    style Stage2 fill:#E8F5E9
    style X1 fill:#FFEBEE
    style X2 fill:#FFEBEE
    style X3 fill:#FFEBEE
    style X4 fill:#FFEBEE
```

---

## Docker Layer Caching

```mermaid
flowchart TB
    subgraph Bad ["❌ Cách Sai (v0)"]
        direction TB
        B1[FROM node:latest]
        B2["COPY . .  ← copy tất cả files"]
        B3["RUN npm install ← invalidate mỗi khi code thay đổi!"]
        B1 --> B2 --> B3
    end

    subgraph Good ["✅ Cách Đúng (v8)"]
        direction TB
        G1[FROM node:22.17-alpine]
        G2["COPY package*.json ./  ← chỉ copy package files"]
        G3["RUN npm ci  ← cache layer này khi package.json không đổi"]
        G4["COPY src/  ← code thay đổi không ảnh hưởng npm ci"]
        G1 --> G2 --> G3 --> G4
    end

    style Bad fill:#FFEBEE
    style Good fill:#E8F5E9
```

### Tại sao thứ tự COPY quan trọng?

Docker cache layer dựa trên:
1. Instruction (FROM, RUN, COPY...)
2. Nội dung files được COPY

Khi `package.json` không thay đổi → layer `RUN npm ci` được cache → build nhanh hơn nhiều.

---

## Security: Non-root User

```mermaid
graph LR
    subgraph Root ["😱 Chạy root (v0)"]
        A1[Process chạy root]
        A2[Container escape = root access to host]
        A3[Write anywhere in container]
    end

    subgraph NonRoot ["✅ Chạy non-root (v8)"]
        B1[Process chạy appuser]
        B2[Container escape = limited user access]
        B3[Read-only except /app]
    end

    Root -->|"Upgrade"| NonRoot

    style Root fill:#FFEBEE
    style NonRoot fill:#E8F5E9
```

```dockerfile
# Tạo group và user không có home directory (-S = system user)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Chuyển sang user này cho mọi lệnh tiếp theo
USER appuser
```

---

## Image Size Comparison

```mermaid
xychart-beta
    title "Image Size (MB)"
    x-axis ["node:latest single-stage", "node:22-slim single-stage", "node:22-alpine single-stage", "Multi-stage alpine (v8)"]
    y-axis "Size (MB)" 0 --> 1200
    bar [1100, 450, 280, 150]
```

---

## .dockerignore — Ngăn Secret Vào Image

Không có `.dockerignore`, lệnh `COPY . .` sẽ copy:

```
❌ node_modules/        (600MB!)
❌ .git/                (git history + secrets)
❌ .env                 (credentials!)
❌ tests/               (không cần trong production)
❌ coverage/            (không cần trong production)
❌ *.secret             (nhạy cảm)
```

Với `.dockerignore`:
```
✅ Chỉ copy src/ và package files
✅ Image nhỏ hơn nhiều
✅ Không rò rỉ secrets vào image
✅ Build nhanh hơn (ít files hơn để upload vào build context)
```
