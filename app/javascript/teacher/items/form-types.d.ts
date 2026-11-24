export type ContentType =
  | 'Video::Video'
  | 'CourseService::Richtext'
  | 'QuizService::Quiz'
  | 'Lti::Exercise'
  | 'Cmi5::Item';

export type ExerciseType = 'main' | 'bonus' | 'selftest' | 'survey' | '';
