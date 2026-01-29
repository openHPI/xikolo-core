import ready from '../../util/ready';
import track from './common';

ready(() => {
  const lanalyticsData = document.querySelector('[data-lanalytics-visit]');

  if (!lanalyticsData) return;

  const verbSuffix = lanalyticsData.dataset.lanalyticsVisit;
  const resource = JSON.parse(lanalyticsData.dataset.lanalyticsResource);

  const context = {};
  if (lanalyticsData.dataset.lanalyticsContext) {
    Object.assign(
      context,
      JSON.parse(lanalyticsData.dataset.lanalyticsContext),
    );
  }

  track(`visited_${verbSuffix}`, resource.uuid, resource.type, context);
});
