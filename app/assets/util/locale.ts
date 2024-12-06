const getLocale = () => {
  let locale = document.documentElement.lang;
  if (locale === 'cn') {
    locale = 'zh';
  }

  if (locale === 'pt-BR') {
    locale = 'pt';
  }

  return locale;
};

export default getLocale;
