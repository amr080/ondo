// Paste the console output here between the backticks
const errors = `PASTE_ERRORS_HERE`;

// Parse and analyze errors
const errorLines = errors.split('\n');
const analysis = errorLines.map(line => {
  if (line.includes('SyntaxError')) {
    return {type: 'syntax', line};
  }
  if (line.includes('ChunkLoadError')) {
    return {type: 'chunk-load', line};
  }
  if (line.includes('TypeError')) {
    return {type: 'type', line};
  }
  return {type: 'unknown', line};
}).filter(x => x.line.trim());

console.log('Error Analysis:', analysis);
