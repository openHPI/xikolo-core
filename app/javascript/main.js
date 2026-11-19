/**
 * Main application bundle
 *
 * Should only be used for shared small functions and
 * initializers. Probably.
 */

// Sentry must be initialized first to capture all errors
import { initSentry } from './util/sentry';
initSentry();

import '@hotwired/turbo-rails';

import './legacy/initializers';
import 'bootstrap/dist/js/bootstrap.min.js';
import Rails from '@rails/ujs';
import * as ActiveStorage from '@rails/activestorage';
import '@videojs/html/video/player';
import '@videojs/html/video/skin';
import '@videojs/html/media/hlsjs-video';

// Rails UJS
Rails.start();
ActiveStorage.start();

import './legacy/helpdesk';

// Analytics
import './analytics/matomo';

/**
 * Stimulus
 */
import { Application } from '@hotwired/stimulus';
import SnowflakesController from './controllers/snowflakes_effect_controller';
import SaveSendToggleController from './controllers/save_send_toggle_controller';
import SubmissionsController from './controllers/submissions_controller';
import NavigationController from './controllers/navigation_controller';
import HideClosestController from './controllers/hide_closest_controller';
import FlashLayerController from './controllers/flash_layer_controller';
import CountdownController from './controllers/countdown_controller';
import CarouselController from './controllers/shorts/carousel_controller';
import QuizRecapController from './controllers/quiz_recap_controller';
import FileUploadController from './controllers/file_upload_controller';
import GuardianConsentController from './controllers/guardian_consent_controller';
import TabsController from './controllers/tabs_controller';
import PasswordToggleController from './controllers/password_toggle_controller';
import QuestionDifficultyController from './controllers/question_difficulty_controller';
import ReadMoreController from './controllers/read_more_controller';
import GlobalCarouselController from './controllers/carousel_controller';
import QuizStepsController from './controllers/quiz_steps_controller';
import ToastController from './controllers/toast_controller';
import FilterBarController from './controllers/filter_bar_controller';

window.Stimulus = Application.start();
window.Stimulus.register('snowflakes_effect', SnowflakesController);
window.Stimulus.register('save_send_toggle', SaveSendToggleController);
window.Stimulus.register('submissions', SubmissionsController);
window.Stimulus.register('navigation', NavigationController);
window.Stimulus.register('hide-closest', HideClosestController);
window.Stimulus.register('flash-layer', FlashLayerController);
window.Stimulus.register('countdown', CountdownController);
window.Stimulus.register('shorts-carousel', CarouselController);
window.Stimulus.register('quiz-recap', QuizRecapController);
window.Stimulus.register('file-upload', FileUploadController);
window.Stimulus.register('guardian-consent', GuardianConsentController);
window.Stimulus.register('tabs', TabsController);
window.Stimulus.register('password-toggle', PasswordToggleController);
window.Stimulus.register('question-difficulty', QuestionDifficultyController);
window.Stimulus.register('read-more', ReadMoreController);
window.Stimulus.register('carousel', GlobalCarouselController);
window.Stimulus.register('quiz-steps', QuizStepsController);
window.Stimulus.register('toast', ToastController);
window.Stimulus.register('filter-bar', FilterBarController);

/*
 * Main components and snippets
 */

import './actions/form/autosubmit';
import './actions/form/change-handler';
import './actions/form/hide-on-submit';
import './actions/form/show-on-submit';
import './actions/form/disable-on-submit';

import './components/global/tooltip';
import './components/global/browser-warning';
import './components/global/cookie-consent-banner';
import './components/global/copy-to-clipboard';
import './components/global/custom-select';
import './components/global/dialog';
import './components/global/flatpickr';
import './components/global/dropdown';
import './components/global/hide-on-click';
import './components/global/markdown-editor';
import './components/global/show-on-click';
import './components/global/slider';
import './components/global/system-alerts';
import './components/global/relative-time';
import './components/global/toggle-menu';
import './components/navigation/tabs';
import './components/video/video-player';

import './util/forms/upload';
import './util/forms/mdupload';

import './user/user';
import './home/home';
import './admin/admin';
import './teacher/teacher';
import './course/course';

/*
 * Legacy
 */

import './legacy/account-profile';
import './legacy/course';
import './legacy/quiz-submission';
import './legacy/course-form';
import './legacy/clone-course';
