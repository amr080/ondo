// Error detector script
(function() {
  const errors = [];
  
  // Store original console.error
  const originalConsoleError = console.error;
  
  // Override console.error to capture errors
  console.error = function(...args) {
    errors.push(args);
    originalConsoleError.apply(console, args);
  };

  // Capture unhandled errors
  window.onerror = function(msg, url, lineNo, columnNo, error) {
    errors.push({
      type: 'runtime',
      message: msg,
      url: url,
      line: lineNo,
      column: columnNo,
      error: error?.stack || error
    });
    return false;
  };

  // Capture unhandled promise rejections
  window.addEventListener('unhandledrejection', function(event) {
    errors.push({
      type: 'promise',
      message: event.reason?.message || event.reason,
      stack: event.reason?.stack
    });
  });

  // Expose errors array
  window.__errors = errors;

  // Add method to get errors
  window.getErrors = function() {
    return JSON.stringify(errors, null, 2);
  };
})();
