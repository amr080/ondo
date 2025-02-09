(function() {
  // Initialize error tracking
  window.__errors = [];
  window.__sentryConfig = {
    dsn: "https://48fb6dd2a1cac566ad87ad4b5425d576@o1112958.ingest.us.sentry.io/6728314",
    environment: "production",
    allowUrls: ["*.ondo.finance", "ondo.finance"],
    beforeSend: (event) => {
      window.__errors.push(event);
      return event;
    }
  };

  // Handle recaptcha errors
  window.recaptchaCallback = function(token) {
    if (!token) {
      window.__errors.push({
        type: 'recaptcha',
        message: 'Failed to get recaptcha token'
      });
    }
  };

  // Handle form submission errors
  window.handleSubmit = function(event) {
    try {
      const form = event.target;
      const email = form.querySelector('input[type="email"]').value;
      
      return new Promise((resolve) => {
        window.grecaptcha.execute('6Lduo6wiAAAAAESScOpS0B60IobUKkpE1waWWAeq', {action: 'submit'})
          .then((token) => {
            // Submission logic here
            resolve(true);
          })
          .catch((error) => {
            window.__errors.push({
              type: 'submission',
              message: error.message
            });
            resolve(false);
          });
      });
    } catch (error) {
      window.__errors.push({
        type: 'form',
        message: error.message
      });
      return false;
    }
  };
})();
