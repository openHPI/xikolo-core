/**
 * A Rails compatible `fetch` wrapper
 *
 * This `fetch` sets headers required for Rails
 * e.g. `X-Requested-With` and `X-CSRF-Token`.
 *
 * @param {RequestInfo} req
 * @param {RequestInit} init
 */
export default function fetch(req, init = {}) {
  const request = new Request(req, {
    ...init,
    credentials: 'same-origin',
  });

  request.headers.set('X-Requested-With', 'XMLHttpRequest');

  const token = document.querySelector('meta[name="csrf-token"]');

  if (request.method.toUpperCase() !== 'GET' && token) {
    request.headers.set('X-CSRF-Token', token.content);
  }

  return window.fetch(request);
}
