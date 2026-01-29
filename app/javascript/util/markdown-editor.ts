import initializeMarkdownEditor from '../components/global/markdown-editor';

/**
 * Adapter for attaching the legacy markdown editor
 */
const initMarkdownEditorOnSelector = (scope: HTMLElement) => {
  initializeMarkdownEditor(scope);
};

export default initMarkdownEditorOnSelector;
