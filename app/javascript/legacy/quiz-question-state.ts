import { turboReady } from '../util/ready';

// Mark quiz questions as edited on page load if they have been answered
turboReady(() => {
  const editedQuestionMetaTags = document.querySelectorAll(
    'meta[name="question-edited"]',
  );

  editedQuestionMetaTags.forEach((metaTag) => {
    const questionId = metaTag.getAttribute('content');
    const indicator = document.getElementById(`${questionId}_indicator`);
    if (indicator) {
      indicator.classList.add('edited');
    }
  });
});
