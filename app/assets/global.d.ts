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

// Platform localization variable
declare const I18n: {
  brand: string;
  locale: string;
  t: (
    token: string,
    interpolationVariables?: { [key: string]: string },
  ) => string;
};

declare module 'html5sortable/dist/html5sortable.es';
