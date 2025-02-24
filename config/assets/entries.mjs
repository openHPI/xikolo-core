/**
 * Returns webpack bundle entries.
 *
 * 'bundle-name': [...files included in bundle]
 *
 * Different to sprockets each bundle can directly
 * include multiple files, JavaScript as well as CSS.
 */
export default async function entries() {
  return {
    main: ['main.js'],
    styles: ['main.scss'],
    bootstrap: ['bootstrap-custom.scss'],
    fontawesome: ['fontawesome.scss'],
    modal: ['modal.js'],

    admin: 'admin/admin.js',
    'collabspace/calendar': 'collabspace/calendar.js',
    course: 'course/course.js',
    home: 'home/home.js',
    teacher: 'teacher/teacher.js',
    user: 'user/user.ts',
    'video-player': 'video-player/video-player.js',
    'quiz-recap': 'quiz-recap/quiz-recap.ts',

    // Legacy
    'lanalytics-framework': 'legacy/lanalytics/index.js',
    'lanalytics-pa-item': 'legacy/lanalytics/visits/peer_assessment_item.js',
    'lanalytics-pa-results':
      'legacy/lanalytics/visits/peer_assessment_results.js',
    'account-profile': 'legacy/account-profile.js',
    'result-box': 'legacy/quiz/result-box.js',
    'peer-assessment-statistics': 'legacy/peer-assessment/statistics.js',
    'admin-legacy': 'legacy/admin.js',
    'course-admin': 'legacy/course.js',

    // Libraries
    dimple: 'legacy/libraries/dimple.js',
    'bootstrap-editable': 'legacy/bootstrap-editable.js',

    // Locales
    'xikolo-locale-en': `i18n/translations/en.ts`,
    'xikolo-locale-de': `i18n/translations/de.ts`,
    'xikolo-locale-es': `i18n/translations/es.ts`,
    'xikolo-locale-fr': `i18n/translations/fr.ts`,
    'xikolo-locale-nl': `i18n/translations/nl.ts`,
    'xikolo-locale-uk': `i18n/translations/uk.ts`,
  };
}
