// Global user variable
declare const gon: {
  user_id?: string;
  in_app?: boolean;
  env?: string;
  build_version?: string;
  item_id?: string;
  section_id?: string;
  course_id?: string;
};

declare module 'html5sortable/dist/html5sortable.es';
declare module 'jquery';

declare module 'i18n/*.json' {
  const value: string;
  export default value;
}
