// 🐛 FILE NÀY CÓ LỖI LINT CỐ Ý - CHỈ DÙNG CHO MỤC ĐÍCH ĐÀO TẠO
// Lỗi 1: Thiếu dấu chấm phẩy (semi: error)
// Lỗi 2: Biến không được sử dụng (no-unused-vars: error)
'use strict';

const express = require('express');
const { add, divide } = require('../services/mathService');

// 🐛 LINT ERROR: biến 'unusedConfig' được khai báo nhưng không bao giờ dùng
//const unusedConfig = { timeout: 5000, retries: 3 };

const router = express.Router();

router.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

router.get('/add', (req, res) => {
  const a = parseFloat(req.query.a);
  const b = parseFloat(req.query.b);
  if (isNaN(a) || isNaN(b)) {
    return res.status(400).json({ error: 'Invalid parameters: a and b must be numbers' });
  }
  res.json(add(a, b));
});

router.get('/divide', (req, res) => {
  const a = parseFloat(req.query.a);
  const b = parseFloat(req.query.b);
  if (isNaN(a) || isNaN(b)) {
    return res.status(400).json({ error: 'Invalid parameters: a and b must be numbers' });
  }
  try {
    res.json(divide(a, b));
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
