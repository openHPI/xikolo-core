/* eslint-disable import/first */
/**
 * Main application bundle
 *
 * Should only be used for shared small functions and
 * initializers. Probably.
 */

// Polyfills
import 'form-request-submit-polyfill';

/*
 * Export global variables used in deprecated sprockets-based
 * javascript assets.
 */

// sweetalert2: Export the XUI mixin as the default for both, plain and
// xuiSwal usage. All legacy code should use the same default config.
import swal from 'util/swal';
import { showLoading, hideLoading } from './util/loading';
import sanitize from './util/sanitize';

window.Swal = swal;
window.xuiSwal = swal;

/**
 * Legacy utility to show and hide loading dimmer
 * Use explicit import instead
 * @deprecated
 */
window.showLoading = showLoading;
window.hideLoading = hideLoading;

/**
 * Legacy utility to sanitize input
 * Use explicit import instead
 * @deprecated
 */
window.sanitize = sanitize;

/*
 * Webpack-native snippets and main components
 */

import 'actions/form/autosubmit';
import 'actions/form/change-handler';
import 'actions/form/hide-on-submit';
import 'actions/form/show-on-submit';
import 'actions/form/disable-on-submit';
import 'actions/form/add-data-on-ajax-success';

import 'components/global/accordion';
import 'components/global/tooltip';
import 'components/global/browser-warning';
import 'components/global/clear-button';
import 'components/global/cookie-consent-banner';
import 'components/global/copy-to-clipboard';
import 'components/global/custom-select';
import 'components/global/expand-course-card';
import 'components/global/flatpickr';
import 'components/global/helpdesk-button';
import 'components/global/dropdown';
import 'components/global/hide-on-click';
import 'components/global/markdown-editor';
import 'components/global/show-on-click';
import 'components/global/fixed-bar';
import 'components/global/slider';
import 'components/global/system-alerts';
import 'components/global/relative-time';
import 'components/global/toggle-menu';
import 'components/navigation/tabs';

import 'util/forms/upload';
import 'util/forms/mdupload';
