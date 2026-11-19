import * as Sentry from '@sentry/browser';

/**
 * Check if all exception frames originate from the page's own HTML document.
 * This is the signature of browser-injected scripts: Chrome iOS Translate,
 * WebView extensions, and translation services report the page URL in every
 * stack frame instead of real bundle assets (e.g. /assets/*.js).
 *
 * When every frame's filename matches the page URL (or is empty), the exception
 * comes from injected code and can be safely dropped.
 *
 * @see WEB-55Q, WEB-540
 */
function isInjectedException(event: Sentry.Event): boolean {
  const firstException = event.exception?.values?.[0];
  if (!firstException) return false;

  const pageOrigin = window.location.origin;
  const pagePath = window.location.pathname;
  const pageUrl = `${pageOrigin}${pagePath}`;

  const frames = firstException.stacktrace?.frames;
  // No frames → no stacktrace → keep the event
  if (!frames?.length) return false;

  return frames.every((frame) => {
    const filename = frame.filename || '';
    // Strip query parameters and hash before comparing
    const cleanFilename = filename.replace(/[?#].*$/, '');
    return !cleanFilename || cleanFilename === pageUrl;
  });
}

/**
 * Initialize Sentry for frontend error tracking.
 *
 * Reads configuration from meta tags injected by the server.
 * Gracefully skips initialization if DSN is not configured.
 */
export function initSentry(): void {
  const dsn = document.querySelector<HTMLMetaElement>(
    'meta[name="sentry-dsn"]',
  )?.content;

  if (!dsn) return;

  const environment = document.querySelector<HTMLMetaElement>(
    'meta[name="sentry-environment"]',
  )?.content;

  Sentry.init({
    dsn,
    environment,
    tracesSampleRate: 0.1,
    initialScope: (scope) => {
      scope.setTag('application', 'frontend');
      scope.setTag('brand', 'openHPI');
      return scope;
    },
    denyUrls: [
      // Filter out browser extensions and injected scripts that are not part of the application.
      /^chrome-extension:\/\//i,
      /^moz-extension:\/\//i,
      /^safari-extension:\/\//i,
    ],
    ignoreErrors: [
      // Browser-specific noise
      'ResizeObserver loop limit exceeded',
      'ResizeObserver loop completed with undelivered notifications',
      // Safari WebExtension content script errors (WEB-3XC) — e.g. "Tab not found"
      'Invalid call to runtime.sendMessage()',
      // Network errors (usually user connectivity issues)
      'Network request failed',
      'Failed to fetch',
      'Load failed',
      'NetworkError when attempting to fetch resource',
    ],
    beforeSend(event) {
      // Drop exceptions whose frames all point at the page's own HTML document.
      if (isInjectedException(event)) {
        return null;
      }
      return event;
    },
  });
}

export { Sentry };
