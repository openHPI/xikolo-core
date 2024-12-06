import ready from 'util/ready';
import fetch from 'util/fetch';

const addErrorModalListener = () => {
  document.addEventListener('click', (event) => {
    if (!event.target.matches('[data-id="show-report-job-error-modal"]'))
      return;

    document.querySelector(
      '[data-id="report-job-error-modal-body"]',
    ).innerHTML = event.target.dataset.error;
  });
};

const fetchReportsJobs = () =>
  fetch('/reports')
    .then((response) => {
      if (!response.ok) throw new Error(response.statusText);
      return response.text();
    })
    .then((html) => {
      document.querySelector('[data-id="report-jobs"]').innerHTML = html;
    });

const pollReportJobs = () => {
  fetchReportsJobs().finally(() => {
    setTimeout(pollReportJobs, 10000);
  });
};

ready(() => {
  const reportJobsElement = document.querySelector('[data-id="report-jobs"]');

  if (!reportJobsElement) return;

  addErrorModalListener();

  pollReportJobs();
});
