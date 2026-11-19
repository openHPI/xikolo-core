/**
 * Piwik/Matomo Analytics Tracker
 * Initializes tracking if configuration is provided via meta tags
 */

import handleError from '../util/error';

// Read configuration from meta tags — skip silently if not configured (e.g. development)
const hostMeta = document.querySelector('meta[name="piwik-host"]');
const siteIdMeta = document.querySelector('meta[name="piwik-site-id"]');

if (hostMeta && siteIdMeta) {
  try {
    var _paq = (window._paq = window._paq || []);

    (function () {
      var protocol =
        'https:' == document.location.protocol ? 'https://' : 'http://';
      var host = hostMeta.getAttribute('content');
      var siteId = siteIdMeta.getAttribute('content');
      var path = '/piwik/';
      var u = protocol + host + path;

      _paq.push(['setSiteId', parseInt(siteId, 10)]);
      _paq.push(['setTrackerUrl', u + 'matomo.php']);
      _paq.push(['setAPIUrl', u]);
      _paq.push(['enableLinkTracking']);

      var g = document.createElement('script');
      var s = document.getElementsByTagName('script')[0];

      g.type = 'text/javascript';
      g.async = true;
      g.src = u + 'matomo.js';

      s.parentNode.insertBefore(g, s);

      // Track subsequent Turbo SPA navigations.
      document.addEventListener('turbo:load', () => {
        window._paq.push(['setCustomUrl', document.location.href]);
        window._paq.push(['setDocumentTitle', document.title]);
        window._paq.push(['trackPageView']);
      });
    })();
  } catch (err) {
    handleError('Piwik tracking initialization failed:', err, false);
  }
}
