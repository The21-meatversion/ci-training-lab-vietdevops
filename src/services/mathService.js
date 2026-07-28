'use strict';

const _ = require('lodash');

/**
 * Cộng hai số.
 * @param {number} a
 * @param {number} b
 * @returns {number}
 */
function add(a, b) {
  if (!_.isNumber(a) || !_.isNumber(b) || isNaN(a) || isNaN(b)) {
    throw new TypeError('Parameters must be numbers');
  }
  return a + b;
}

/**
 * Chia a cho b.
 * @param {number} a
 * @param {number} b
 * @returns {number}
 */
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
