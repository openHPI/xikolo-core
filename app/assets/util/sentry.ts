import * as Sentry from '@sentry/browser';

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

  const brand = document.documentElement.dataset.brand;

  Sentry.init({
    dsn,
    environment,
    tracesSampleRate: 0.1,
    initialScope: (scope) => {
      scope.setTag('application', 'frontend');
      if (brand) {
        scope.setTag('brand', brand);
      }
      return scope;
    },
    ignoreErrors: [
      // Browser-specific noise
      'ResizeObserver loop limit exceeded',
      'ResizeObserver loop completed with undelivered notifications',
      // Network errors (usually user connectivity issues)
      'Network request failed',
      'Failed to fetch',
      'Load failed',
    ],
  });
}

export { Sentry };
