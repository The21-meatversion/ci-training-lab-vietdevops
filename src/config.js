// 🔴 LỖI BẢO MẬT NGHIÊM TRỌNG: HARDCODED SECRET - CHỈ DÙNG CHO MỤC ĐÍCH ĐÀO TẠO
// Vấn đề: API Key được hardcode trực tiếp trong source code.
// Khi commit lên git, secret này sẽ tồn tại mãi trong git history!
// Bất kỳ ai có quyền đọc repository đều có thể thấy secret này.
'use strict';

const config = {
  // 🐛 SECURITY BUG: KHÔNG BAO GIỜ hardcode secret trong code!
  // Sử dụng biến môi trường thay thế: process.env.API_KEY
  //apiKey: 'sk-training-hardcoded-key-do-not-use-in-prod',
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
};

if (!config.apiKey && process.env.NODE_ENV !== 'test') {
  console.warn('WARNING: API_KEY is not set');
}

module.exports = config;
