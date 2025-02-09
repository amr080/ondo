const fs = require('fs');
const path = require('path');

function validateBuild() {
  const errors = [];
  const warnings = [];

  // Check critical files
  const requiredFiles = [
    'index.html',
    'fix-head.js',
    'error-monitor.js'
  ];

  requiredFiles.forEach(file => {
    if (!fs.existsSync(file)) {
      errors.push(`Missing critical file: ${file}`);
    }
  });

  // Validate JS files
  const jsFiles = fs.readdirSync('.').filter(f => f.endsWith('.js'));
  jsFiles.forEach(file => {
    try {
      require(`./${file}`);
    } catch (e) {
      errors.push(`Invalid JS in ${file}: ${e.message}`);
    }
  });

  // Check chunk sizes
  const chunks = path.join('_next', 'static', 'chunks');
  if (fs.existsSync(chunks)) {
    fs.readdirSync(chunks).forEach(file => {
      const stats = fs.statSync(path.join(chunks, file));
      if (stats.size > 2000000) {
        warnings.push(`Large chunk file (>2MB): ${file}`);
      }
    });
  }

  return { errors, warnings };
}

const results = validateBuild();
console.log('Build Validation Results:');
console.log('Errors:', results.errors);
console.log('Warnings:', results.warnings);

if (results.errors.length > 0) {
  process.exit(1);
}
