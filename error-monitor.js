(function() {
  const errorLog = {
    errors: [],
    warnings: [],
    resources: new Map(),
    network: [],
    performance: []
  };

  // Resource loading monitor
  const observer = new PerformanceObserver((list) => {
    list.getEntries().forEach(entry => {
      errorLog.resources.set(entry.name, {
        duration: entry.duration,
        size: entry.transferSize,
        type: entry.initiatorType,
        failed: !entry.responseEnd
      });
    });
  });
  observer.observe({ entryTypes: ['resource'] });

  // Network error tracking
  const originalFetch = window.fetch;
  window.fetch = function(...args) {
    return originalFetch.apply(this, args)
      .catch(error => {
        errorLog.network.push({
          url: args[0],
          error: error.message,
          timestamp: Date.now()
        });
        throw error;
      });
  };

  // Error and warning capture
  window.onerror = function(msg, url, line, col, error) {
    errorLog.errors.push({
      type: 'runtime',
      message: msg,
      location: { url, line, col },
      stack: error?.stack,
      timestamp: Date.now()
    });
    return false;
  };

  console.error = function(...args) {
    errorLog.errors.push({
      type: 'console',
      message: args.join(' '),
      timestamp: Date.now()
    });
  };

  // Performance monitoring
  window.addEventListener('load', () => {
    const timing = performance.timing;
    errorLog.performance.push({
      loadTime: timing.loadEventEnd - timing.navigationStart,
      domReady: timing.domContentLoadedEventEnd - timing.navigationStart,
      firstPaint: performance.getEntriesByType('paint')[0]?.startTime
    });
  });

  // Expose diagnostic functions
  window.diagnostics = {
    getErrors: () => JSON.stringify(errorLog.errors, null, 2),
    getWarnings: () => JSON.stringify(errorLog.warnings, null, 2),
    getResourceStats: () => JSON.stringify(Array.from(errorLog.resources.entries()), null, 2),
    getNetworkIssues: () => JSON.stringify(errorLog.network, null, 2),
    getPerformance: () => JSON.stringify(errorLog.performance, null, 2),
    getFullReport: () => JSON.stringify(errorLog, null, 2)
  };
})();
