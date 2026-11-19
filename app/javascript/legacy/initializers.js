/*
 * Export global variables used in deprecated javascript assets.
 *
 * Note:
 * The code is deliberately setting global variables on the window object.
 * These assignments are intentional side effects that run when the module is imported,
 * making these utilities available to legacy inline JavaScript code.
 */

import jQuery from 'jquery';
/**
 * jQuery for legacy bootstrap JS.
 * @deprecated
 */
window.jQuery = jQuery;
