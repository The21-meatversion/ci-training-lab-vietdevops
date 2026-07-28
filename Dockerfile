# ⚠️  DOCKERFILE NÀY CÓ NHIỀU VẤN ĐỀ BẢO MẬT - CHỈ DÙNG CHO MỤC ĐÍCH ĐÀO TẠO ⚠️
#
# Vấn đề 1: Dùng tag 'latest' - image có thể thay đổi bất ngờ
# Vấn đề 2: Chạy với user root - rủi ro bảo mật cao
# Vấn đề 3: COPY . . trước npm install - phá vỡ Docker layer cache
# Vấn đề 4: Không có .dockerignore - copy cả node_modules, .git, .env vào image
# Vấn đề 5: npm install thay vì npm ci - không đảm bảo version nhất quán
# Vấn đề 6: Không có HEALTHCHECK
# Vấn đề 7: Single stage - dev dependencies được copy vào production image

FROM node:latest

WORKDIR /app

COPY . .

RUN npm install

EXPOSE 3000

CMD ["node", "src/app.js"]
