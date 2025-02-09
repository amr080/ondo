// Initialize window and document objects
(function() {
  if (typeof window === 'undefined') {
    global.window = {};
  }
  if (typeof document === 'undefined') {
    global.document = {
      head: null,
      getElementsByTagName: function() { return [{}] }
    };
  }
  
  window.document = window.document || {};
  window.document.head = window.document.head || document.getElementsByTagName("head")[0];
  window.__next_f = window.__next_f || [];
  
  // Fix chunk loading
  window.__webpack_public_path__ = window.location.origin + '/static/chunks/';
})();
