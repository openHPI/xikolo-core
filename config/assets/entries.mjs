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
    'lanalytics-framework': 'legacy/lanalytics/index.js',
    'lanalytics-pa-item': 'legacy/lanalytics/visits/peer_assessment_item.js',
    'lanalytics-pa-results':
      'legacy/lanalytics/visits/peer_assessment_results.js',
  };
}
