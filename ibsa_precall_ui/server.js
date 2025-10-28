#!/usr/bin/env node
const { spawn } = require('child_process');
const path = require('path');

// Start Next.js in production mode
const nextBin = path.join(__dirname, 'node_modules', 'next', 'dist', 'bin', 'next');
const next = spawn('node', [nextBin, 'start'], {
  stdio: 'inherit',
  env: { ...process.env, PORT: process.env.PORT || 8080 }
});

next.on('error', (err) => {
  console.error('Failed to start Next.js:', err);
  process.exit(1);
});

next.on('exit', (code) => {
  process.exit(code);
});
