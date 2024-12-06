import Cookies from 'js-cookie';

function getDefaultContext(lanalyticsData, contextData) {
  const context = {};

  // To pass their native context data this cookie can be set by the
  // mobile apps. They use embedded web views to display some content.
  const contextCookie = Cookies.get('lanalytics-context');
  if (lanalyticsData.in_app && contextCookie) {
    Object.assign(context, JSON.parse(contextCookie));
  } else {
    context.user_agent = window.navigator && window.navigator.userAgent;
    context.screen_width = window.screen && window.screen.width;
    context.screen_height = window.screen && window.screen.height;
    if (lanalyticsData.build_version) {
      context.build_version = lanalyticsData.build_version;
    }
  }

  Object.assign(context, contextData);

  return context;
}

/**
 * Track lanalytics event
 *
 * @param {String} verb
 * @param {String} resourceId
 * @param {String} resourceType
 * @param {Object} context
 * @param {Object} result
 */
export default function track(
  verb,
  resourceId,
  resourceType,
  context = {},
  result = {},
) {
  const lanalyticsElement = document.querySelector(
    "meta[name='lanalytics-data']",
  );
  const lanalyticsData = JSON.parse(lanalyticsElement.content);

  if (lanalyticsData.user_id === undefined) return;

  const userObj = new window.Lanalytics.Model.StmtUser(lanalyticsData.user_id);
  const resObj = new window.Lanalytics.Model.StmtResource(
    resourceType,
    resourceId,
  );

  const defaultContext = getDefaultContext(lanalyticsData, context);

  const l = new window.Lanalytics.Framework();
  l.track(userObj, verb, resObj, result, defaultContext);
}
