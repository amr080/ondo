// Test script to verify initialization
(function() {
  console.log('Testing initialization...');
  const tests = {
    'window exists': typeof window !== 'undefined',
    'document exists': typeof document !== 'undefined',
    'head exists': document && document.head,
    'next_f array exists': window.__next_f instanceof Array
  };
  
  Object.entries(tests).forEach(([test, result]) => {
    console.log(`${test}: ${result ? '✓' : '✗'}`);
  });
})();
