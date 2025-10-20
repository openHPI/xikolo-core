/**
 * Returns webpack bundle entries.
 *
 * 'bundle-name': [...files included in bundle]
 *
 * Different to sprockets each bundle can directly
 * include multiple files, JavaScript as well as CSS.
 */
import { join } from 'path';
import { existsSync } from 'fs';
import { colors } from './helpers.mjs';

export default async function entries(settings = {}) {
  const { root } = settings;

  // Detect whether Font Awesome Pro sources are present. If not, use a stub
  // stylesheet to still emit a fontawesome.css bundle to satisfy layout tags.
  const faProDir = join(root, 'app', 'assets', 'fontawesome-pro');
  const hasFontAwesomePro = existsSync(faProDir);
  const fontawesomeEntry = hasFontAwesomePro
    ? 'fontawesome.scss'
    : 'fontawesome.stub.scss';

  if (!hasFontAwesomePro) {
    // eslint-disable-next-line no-console
    console.warn(
      colors.yellow('WARNING: Font Awesome Pro not detected.'),
      'The application will have no icons available. If you have a license, please add the source files to',
      colors.green('app/assets/fontawesome-pro'),
    );
  }

  return {
    main: ['main.js'],
    styles: ['main.scss'],
    bootstrap: ['bootstrap-custom.scss'],
    fontawesome: [fontawesomeEntry],
    tailwind: ['tailwind/output.css'],

    admin: 'admin/admin.js',
    course: 'course/course.js',
    home: 'home/home.js',
    teacher: 'teacher/teacher.js',
    user: 'user/user.ts',
    'video-player': 'video-player/video-player.js',
    'quiz-recap': 'quiz-recap/quiz-recap.ts',

    // Legacy
    'lanalytics-framework': 'legacy/lanalytics/index.js',
    'account-profile': 'legacy/account-profile.js',
    'result-box': 'legacy/quiz/result-box.js',
    'admin-legacy': 'legacy/admin.js',
    'course-admin': 'legacy/course.js',

    // Libraries
    dimple: 'legacy/libraries/dimple.js',
    'bootstrap-editable': 'legacy/bootstrap-editable.js',

    // Locales
    'xikolo-locale-en': `i18n/translations/en.ts`,
    'xikolo-locale-de': `i18n/translations/de.ts`,
  };
}
