'use strict';

const express = require('express');
const apiRouter = require('./routes/api');
const config = require('./config');

const app = express();

app.use(express.json());
app.use('/', apiRouter);

if (require.main === module) {
  app.listen(config.port, () => {
    console.log(`Server running on port ${config.port}`);
    console.log(`Environment: ${config.nodeEnv}`);
  });
}

module.exports = app;
