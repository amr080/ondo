(function() {
  window.recaptchaOptions = {
    sitekey: '6Lduo6wiAAAAAESScOpS0B60IobUKkpE1waWWAeq',
    size: 'invisible',
    callback: 'recaptchaCallback'
  };
  
  // Load recaptcha API
  const script = document.createElement('script');
  script.src = 'https://www.google.com/recaptcha/api.js?render=6Lduo6wiAAAAAESScOpS0B60IobUKkpE1waWWAeq';
  script.async = true;
  script.defer = true;
  document.head.appendChild(script);
})();
