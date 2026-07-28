'use strict';

const { add, divide } = require('../src/services/mathService');

describe('mathService - add()', () => {
  test('cộng hai số dương', () => {
    // ✅ FIX: Sửa kết quả mong đợi đúng: 1 + 2 = 3
    expect(add(1, 2)).toBe(3);
  });

  test('cộng hai số âm', () => {
    expect(add(-1, -2)).toBe(-3);
  });

  test('cộng với số 0', () => {
    expect(add(0, 5)).toBe(5);
  });

  test('cộng số thực', () => {
    expect(add(1.5, 2.5)).toBe(4);
  });

  test('ném TypeError khi a không phải số', () => {
    expect(() => add('a', 2)).toThrow(TypeError);
    expect(() => add('a', 2)).toThrow('Parameters must be numbers');
  });

  test('ném TypeError khi b là null', () => {
    expect(() => add(1, null)).toThrow(TypeError);
  });
});

describe('mathService - divide()', () => {
  test('chia hai số nguyên', () => {
    expect(divide(10, 2)).toBe(5);
  });

  test('chia trả về số thực', () => {
    expect(divide(7, 2)).toBe(3.5);
  });

  test('ném Error khi chia cho 0', () => {
    expect(() => divide(10, 0)).toThrow(Error);
    expect(() => divide(10, 0)).toThrow('Division by zero is not allowed');
  });

  test('ném TypeError khi tham số a không hợp lệ', () => {
    expect(() => divide('x', 2)).toThrow(TypeError);
  });

  test('ném TypeError khi tham số b không hợp lệ', () => {
    expect(() => divide(10, 'y')).toThrow(TypeError);
  });
});
