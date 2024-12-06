export type InitState = {
  proctoring: boolean;
  isNotProctoringType: boolean;
};

export type ContentType =
  | 'video'
  | 'rich_text'
  | 'quiz'
  | 'lti_exercise'
  | 'peer_assessment';

export type ExerciseType = 'main' | 'bonus' | 'selftest' | 'survey' | '';
