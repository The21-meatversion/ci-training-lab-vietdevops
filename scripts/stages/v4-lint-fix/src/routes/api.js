'use strict';

const express = require('express');
const { add, divide } = require('../services/mathService');

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
