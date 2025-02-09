(function() {
  // Environment checks
  const checks = {
    window: {
      exists: typeof window !== 'undefined',
      nextF: window && Array.isArray(window.__next_f),
      location: window && typeof window.location === 'object'
    },
    document: {
      exists: typeof document !== 'undefined',
      head: document && document.head instanceof Node,
      body: document && document.body instanceof Node
    },
    performance: {
      exists: typeof performance !== 'undefined',
      timing: performance && typeof performance.timing === 'object'
    }
  };

  // Log results
  console.log('Environment Verification:');
  Object.entries(checks).forEach(([category, tests]) => {
    console.log(`\n${category}:`);
    Object.entries(tests).forEach(([test, result]) => {
      console.log(`  ${test}: ${result ? '✓' : '✗'}`);
    });
  });
})();
