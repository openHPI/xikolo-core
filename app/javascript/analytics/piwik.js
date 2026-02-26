/**
 * Piwik/Matomo Analytics Tracker
 * Initializes tracking if configuration is provided via meta tags
 */

import handleError from '../util/error';
import ready from '../util/ready';

ready(() => {
  try {
    // Read configuration from meta tags
    const hostMeta = document.querySelector('meta[name="piwik-host"]');
    const siteIdMeta = document.querySelector('meta[name="piwik-site-id"]');

    var _paq = _paq || [];

    (function () {
      var protocol =
        'https:' == document.location.protocol ? 'https://' : 'http://';
      var host = hostMeta.getAttribute('content');
      var siteId = siteIdMeta.getAttribute('content');
      var path = '/piwik/';
      var u = protocol + host + path;

      _paq.push(['setSiteId', parseInt(siteId, 10)]);
      _paq.push(['setTrackerUrl', u + 'piwik.php']);
      _paq.push(['setAPIUrl', u]);
      _paq.push(['trackPageView']);
      _paq.push(['enableLinkTracking']);

      var d = document;
      var g = d.createElement('script');
      var s = d.getElementsByTagName('script')[0];

      g.type = 'text/javascript';
      g.defer = true;
      g.async = true;
      g.src = u + 'js/';

      s.parentNode.insertBefore(g, s);
    })();
  } catch (err) {
    handleError('Piwik tracking initialization failed:', err, false);
  }
});
