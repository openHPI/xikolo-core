import { turboReady } from '../../../util/ready';
import handleError from '../../../util/error';

const MARKDOWN_EDITOR_SELECTOR = '[data-behavior="markdown-editor-wrapper"]';
const MARKDOWN_EDITOR_WIDGET_SELECTOR =
  '[data-behavior="markdown-editor-widget"]';
const MARKDOWN_EDITOR_LOADING_SELECTOR =
  '[data-behavior="markdown-editor-loading"]';

const clearLoading = (widgets: HTMLElement[]) => {
  widgets.forEach((widget) => {
    widget.querySelector(MARKDOWN_EDITOR_LOADING_SELECTOR)?.remove();
    widget.closest(MARKDOWN_EDITOR_SELECTOR)?.removeAttribute('aria-busy');
  });
};

export const loadMarkdownEditors = async (
  scope: Document | HTMLElement = document,
) => {
  const widgets = Array.from(
    scope.querySelectorAll<HTMLElement>(
      `${MARKDOWN_EDITOR_SELECTOR}:not([data-markdown-initialized]) ${MARKDOWN_EDITOR_WIDGET_SELECTOR}`,
    ),
  );

  if (widgets.length === 0) return;

  const { default: initializeMarkdownEditor } = await import('./editor');

  try {
    initializeMarkdownEditor(scope);
    clearLoading(widgets);
  } catch (err) {
    clearLoading(widgets);
    handleError(undefined, err);
  }
};

turboReady(() => {
  void loadMarkdownEditors();
});

// turbo:render handles 422 re-renders where turbo:load does not fire.
document.addEventListener('turbo:render', () => {
  void loadMarkdownEditors();
});
