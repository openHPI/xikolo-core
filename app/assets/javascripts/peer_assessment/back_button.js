// Goes back in history (to preserve GET params). Preliminary and thus simple implementation
ready(function () {
  $('.js-back-button').each(function (index, element) {
    $(element).click(function () {
      if (document.referrer.split('/')[2] == location.host) {
        window.location.href = document.referrer;
      } else {
        window.location.href = $(element).data('alternative-url');
      }
    });
  });
});
