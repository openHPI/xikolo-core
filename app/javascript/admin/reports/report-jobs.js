import { turboReady } from '../../util/ready';
import fetch from '../../util/fetch';

document.addEventListener('click', (event) => {
  if (!event.target.matches('[data-id="show-report-job-error-modal"]')) return;

  document.querySelector('[data-id="report-job-error-modal-body"]').innerHTML =
    event.target.dataset.error;
});

const fetchReportsJobs = (signal) =>
  fetch('/reports', { signal })
    .then((response) => {
      if (!response.ok) throw new Error(response.statusText);
      return response.text();
    })
    .then((html) => {
      document.querySelector('[data-id="report-jobs"]').innerHTML = html;
    });

turboReady(() => {
  const reportJobsElement = document.querySelector('[data-id="report-jobs"]');

  if (!reportJobsElement) return;

  const controller = new AbortController();
  const { signal } = controller;

  let timeoutId;

  const pollReportJobs = () => {
    fetchReportsJobs(signal).finally(() => {
      if (!signal.aborted) {
        timeoutId = setTimeout(pollReportJobs, 10000);
      }
    });
  };

  pollReportJobs();

  document.addEventListener(
    'turbo:before-cache',
    () => {
      controller.abort();
      clearTimeout(timeoutId);
    },
    { once: true },
  );
});
