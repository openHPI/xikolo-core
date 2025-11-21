/**
 * Main application bundle
 *
 * Should only be used for shared small functions and
 * initializers. Probably.
 */

// Polyfills
import 'form-request-submit-polyfill';

import './legacy/initializers';
import '../../vendor/assets/javascripts/bootstrap.min.js';
import Rails from '@rails/ujs';

// Rails UJS
Rails.start();

import './legacy/helpdesk';

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
import 'util/get-relative-time';
// XI-6736: Seasonal snow effect
import 'util/snowflakes-effect';
