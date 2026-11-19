import { loadMarkdownEditors } from '../components/global/markdown-editor/index';

/**
 * Adapter for attaching the markdown editor
 */
const initMarkdownEditorOnSelector = (scope: HTMLElement) => {
  loadMarkdownEditors(scope);
};

export default initMarkdownEditorOnSelector;
