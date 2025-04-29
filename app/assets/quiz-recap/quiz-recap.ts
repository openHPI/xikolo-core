import renderQuizRecap, {
  AnswerType,
  Data,
  QuestionType,
  QuizType,
} from '@openhpi/quiz-recap';

import I18n from '../i18n/i18n';

import ready from '../util/ready';
import handleError from '../util/error';
import fetch from '../util/fetch';

type XiQuestion = {
  id: string;
  points: number;
  type:
    | 'Xikolo::Quiz::MultipleChoiceQuestion'
    | 'Xikolo::Quiz::MultipleAnswerQuestion';
  text: string;
  courseId: string;
  quizId: string;
  referenceLink: string;
  answers: AnswerType[];
};

/**
 * Map the type of question in xikolo to the type used in the quiz-recap component.
 * There is no established convention types of multiple choice questions.
 */
const mapQuestionType = (type: string): string => {
  if (type === 'Xikolo::Quiz::MultipleAnswerQuestion') {
    return 'multiple-choice';
  }
  return 'single-choice';
};

const mapAnswersToQuestions = (data: XiQuestion[]): Data => {
  const mappedQuestions = data.map((question: XiQuestion): QuestionType => {
    const questionType = mapQuestionType(question.type);

    const qu: QuestionType = {
      ...question,
      type: questionType as QuizType,
    };

    return qu;
  });

  return mappedQuestions;
};

const showEmptyState = () => {
  const emptyState = document.getElementById('quiz-recap__empty-state')!;
  emptyState.hidden = false;
};

const hideLoadingIndicator = () => {
  const loadingIndicator = document.getElementById(
    'quiz-recap__loading-indicator',
  )!;
  loadingIndicator.hidden = true;
};

const isLangSupported = (lang: string) => ['en', 'de'].includes(lang);
const fallbackLang = isLangSupported(navigator.language)
  ? navigator.language
  : 'en';

ready(async () => {
  if (!document.getElementById('quiz-recap')) return;

  try {
    const courseId = gon.course_id;
    const url = `app/quiz-recap?course_id=${courseId}`;

    const response = await fetch(url, {});
    const data = await response.json();
    const questions = data.questions as XiQuestion[];

    if (questions.length === 0) {
      showEmptyState();
    } else {
      const bestLang = isLangSupported(I18n.locale)
        ? I18n.locale
        : fallbackLang;
      renderQuizRecap('quiz-recap', mapAnswersToQuestions(questions), bestLang);
    }
  } catch (error) {
    handleError(I18n.t('errors.server.generic_message'), error);
  }
  hideLoadingIndicator();
});
