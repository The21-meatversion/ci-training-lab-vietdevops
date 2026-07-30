// 🐛 FILE NÀY CÓ LỖI LINT CỐ Ý - CHỈ DÙNG CHO MỤC ĐÍCH ĐÀO TẠO
// Lỗi 1: Thiếu dấu chấm phẩy
// Lỗi 2: Biến 'version' không được sử dụng
'use strict';

const _ = require('lodash');

// 🐛 LINT ERROR: biến 'version' được khai báo nhưng không bao giờ dùng
//const version = '1.0.0';

function add(a, b) {
  if (!_.isNumber(a) || !_.isNumber(b) || isNaN(a) || isNaN(b)) {
    throw new TypeError('Parameters must be numbers');
  }
  return a + b;
}

function divide(a, b) {
  if (!_.isNumber(a) || !_.isNumber(b) || isNaN(a) || isNaN(b)) {
    throw new TypeError('Parameters must be numbers');
  }
  if (b === 0) {
    throw new Error('Division by zero is not allowed');
  }
  return a / b;
}

module.exports = { add, divide };
