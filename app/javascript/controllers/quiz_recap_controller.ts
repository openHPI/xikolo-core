import { Controller } from '@hotwired/stimulus';
import type { Root } from 'react-dom/client';
import type {
  AnswerType,
  Data,
  QuestionType,
  QuizType,
} from '@openhpi/quiz-recap';

import I18n, { loadTranslations } from '../i18n/i18n';
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

const mapQuestionType = (type: XiQuestion['type']): QuizType => {
  if (type === 'Xikolo::Quiz::MultipleAnswerQuestion') {
    return 'multiple-choice' as QuizType;
  }

  return 'single-choice' as QuizType;
};

const mapAnswersToQuestions = (data: XiQuestion[]): Data =>
  data.map((question): QuestionType => ({
    ...question,
    type: mapQuestionType(question.type),
  }));

const isLangSupported = (lang: string) => ['en', 'de'].includes(lang);

export default class extends Controller<HTMLElement> {
  static targets = ['emptyState', 'loadingIndicator', 'root'];
  static values = { url: String };

  declare readonly emptyStateTarget: HTMLElement;
  declare readonly loadingIndicatorTarget: HTMLElement;
  declare readonly rootTarget: HTMLElement;
  declare readonly urlValue: string;

  private root?: Root;
  private abortController?: AbortController;

  private readonly beforeCache = () => {
    this.teardown();
    this.emptyStateTarget.hidden = true;
    this.loadingIndicatorTarget.hidden = false;
  };

  connect() {
    document.addEventListener('turbo:before-cache', this.beforeCache);
    void this.mount();
  }

  disconnect() {
    document.removeEventListener('turbo:before-cache', this.beforeCache);
    this.teardown();
  }

  private async mount() {
    const controller = new AbortController();
    this.abortController = controller;

    try {
      const [{ default: renderQuizRecap }, response] = await Promise.all([
        import('@openhpi/quiz-recap'),
        fetch(this.urlValue, { signal: controller.signal }),
        loadTranslations(),
      ]);
      const data = await response.json();

      if (!this.isActive(controller.signal)) return;

      const questions = data.questions as XiQuestion[];

      if (questions.length === 0) {
        this.emptyStateTarget.hidden = false;
        return;
      }

      const browserLang = isLangSupported(navigator.language)
        ? navigator.language
        : 'en';
      const locale = isLangSupported(I18n.locale) ? I18n.locale : browserLang;

      this.root = renderQuizRecap(
        this.rootTarget.id,
        mapAnswersToQuestions(questions),
        locale,
      );
    } catch (error) {
      if (controller.signal.aborted) return;

      handleError(I18n.t('errors.server.generic_message'), error);
    } finally {
      if (this.isActive(controller.signal)) {
        this.loadingIndicatorTarget.hidden = true;
        this.abortController = undefined;
      }
    }
  }

  private isActive(signal: AbortSignal) {
    return !signal.aborted && this.element.isConnected;
  }

  private teardown() {
    this.abortController?.abort();
    this.abortController = undefined;
    this.root?.unmount();
    this.root = undefined;
  }
}
