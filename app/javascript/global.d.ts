declare module 'html5sortable/dist/html5sortable.es';
declare module 'jquery';

declare module 'i18n/*.json' {
  const value: string;
  export default value;
}

/// <reference types="@hotwired/turbo" />
interface Window {
  Turbo?: typeof Turbo;
}
