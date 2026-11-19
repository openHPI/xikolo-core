import { Controller } from '@hotwired/stimulus';

// Manages the daisyUI quiz steps component: marks a question step as answered
// (via the `data-answered` attribute used by the Tailwind `data-answered:`
// variants), keeps the "answered" counter in sync, and expands the matching
// accordion section when a step or a Previous/Next footer button is clicked.
//
// The elements are looked up directly (rather than via Stimulus targets)
// because they are not always present: the edit page has the form, counter,
// and steps, while the results page only has the steps. Stimulus has no notion
// of an "optional" target, so a missing one would make a required target
// throw.
export default class extends Controller {
  // The form is a sibling of the card (the anchor element), not a descendant,
  // so it is resolved against the document. There is only one quiz form per
  // page.
  private get form(): HTMLFormElement | null {
    return document.querySelector<HTMLFormElement>('form#quiz_form');
  }

  private get indicators(): HTMLElement | null {
    return this.element.querySelector<HTMLElement>('#quiz-state-indicators');
  }

  private get counter(): HTMLElement | null {
    return this.element.querySelector<HTMLElement>('#quiz-answered-count');
  }

  connect() {
    const form = this.form;
    if (form) {
      // Delegation on the form covers both the `change` listener (choice
      // inputs) and the `input` listener (free-text inputs).
      form.addEventListener('change', this.handleChange);
      form.addEventListener('input', this.handleInput);
      form.addEventListener('click', this.handleNavigation);
      this.markAnsweredFromMetaTags();
    }

    const indicators = this.indicators;
    if (indicators) {
      indicators.querySelectorAll<HTMLAnchorElement>('a').forEach((step) => {
        step.addEventListener('click', this.handleStepClick);
      });
    }

    this.syncAnsweredCount();
  }

  disconnect() {
    const form = this.form;
    if (form) {
      form.removeEventListener('change', this.handleChange);
      form.removeEventListener('input', this.handleInput);
      form.removeEventListener('click', this.handleNavigation);
    }

    const indicators = this.indicators;
    if (indicators) {
      indicators.querySelectorAll<HTMLAnchorElement>('a').forEach((step) => {
        step.removeEventListener('click', this.handleStepClick);
      });
    }
  }

  private handleChange = (event: Event) => {
    const target = event.target as HTMLElement;
    const quizQuestion = target.closest<HTMLElement>('.quiz-question');
    if (!quizQuestion || !quizQuestion.id) {
      return;
    }

    // Free-text questions are handled by the input listener below.
    if (quizQuestion.querySelector('input[type=text], textarea')) {
      return;
    }

    const answered = quizQuestion.querySelector('input:checked') !== null;
    this.setStepAnswered(quizQuestion.id, answered);
  };

  private handleInput = (event: Event) => {
    const target = event.target as HTMLElement;
    const quizQuestion = target.closest<HTMLElement>('.quiz-question');
    if (!quizQuestion || !quizQuestion.id) {
      return;
    }

    const inputs = Array.from(quizQuestion.querySelectorAll('input, textarea'));
    const answered = inputs.some((input) => {
      const el = input as HTMLInputElement;
      return (el.value ?? '').length > 0;
    });
    this.setStepAnswered(quizQuestion.id, answered);
  };

  private handleNavigation = (event: Event) => {
    const button = (event.target as Element).closest<HTMLElement>(
      '[data-quiz-steps-navigation]',
    );
    if (!button) return;

    const direction = button.dataset.quizStepsNavigation;
    if (direction !== 'previous' && direction !== 'next') return;

    const section = button.closest('details');
    if (!section?.parentElement) return;

    const sections = Array.from(
      section.parentElement.querySelectorAll<HTMLDetailsElement>(
        ':scope > details',
      ),
    );
    const index = sections.indexOf(section);
    if (index === -1) return;

    const target = sections[index + (direction === 'next' ? 1 : -1)];
    if (!target) return;

    target.open = true;
    target.querySelector('summary')?.focus({ preventScroll: true });
    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  private handleStepClick = (event: Event) => {
    const step = event.currentTarget as HTMLAnchorElement;
    const sectionId = step.getAttribute('href')?.slice(1);
    if (!sectionId) {
      return;
    }
    const section = document
      .getElementById(`accordion-section-${sectionId}`)
      ?.closest('details');
    if (section) {
      section.open = true;
    }
  };

  private setStepAnswered(questionId: string, answered: boolean) {
    const step = document.getElementById(`${questionId}_indicator`);
    if (step) {
      if (answered) {
        step.setAttribute('data-answered', 'true');
      } else {
        step.removeAttribute('data-answered');
      }
    }
    this.setQuestionAnsweredBadge(questionId, answered);
    this.syncAnsweredCount();
  }

  private setQuestionAnsweredBadge(questionId: string, answered: boolean) {
    const badge = document.querySelector<HTMLElement>(
      `summary[aria-controls="accordion-section-${questionId}"] [data-quiz-steps-answered-badge]`,
    );
    if (badge) {
      badge.hidden = !answered;
    }
  }

  private markAnsweredFromMetaTags() {
    document
      .querySelectorAll('meta[name="question-edited"]')
      .forEach((metaTag) => {
        const questionId = metaTag.getAttribute('content');
        if (questionId) {
          this.setStepAnswered(questionId, true);
        }
      });
  }

  private syncAnsweredCount() {
    const indicators = this.indicators;
    const counter = this.counter;
    if (!indicators || !counter) {
      return;
    }

    const answered = indicators.querySelectorAll(
      '.x-step[data-answered]',
    ).length;
    const total = indicators.querySelectorAll('.x-step').length;
    const template = counter.dataset.template || '';

    counter.textContent = template
      .replace(/%{answered}/g, String(answered))
      .replace(/%{total}/g, String(total));
  }
}
