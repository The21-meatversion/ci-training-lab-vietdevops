'use strict';

/**
 * Cấu hình ứng dụng.
 * ✅ Mọi giá trị nhạy cảm được đọc từ biến môi trường.
 * KHÔNG BAO GIỜ hardcode secret trực tiếp vào source code.
 */
const config = {
  // ✅ FIX: Đọc API key từ biến môi trường thay vì hardcode
  apiKey: process.env.API_KEY || '',
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
};

if (config.nodeEnv !== 'test' && !config.apiKey) {
  console.warn('WARNING: API_KEY environment variable is not set.');
}

module.exports = config;
