ready(function () {
  $('.delete_review').each(function (index, element) {
    $(element).submit(function (e) {
      e.preventDefault();

      xuiSwal
        .fire({
          title: I18n.t('peer_assessment.train_samples.delete_review_title'),
          text: I18n.t('peer_assessment.train_samples.delete_review'),
          icon: 'warning',
          confirmButtonText: I18n.t('global.confirm'),
          cancelButtonText: I18n.t('global.cancel'),
        })
        .then(function (result) {
          if (result.value) {
            showLoading();
            $(element).off('submit');
            $(element).submit();
          }
        });

      return false;
    });
  });

  $('.js-show-loader').each(function (index, element) {
    $(element).click(function () {
      return showLoading();
    });
  });

  $('#open_training_form').submit(function (e) {
    e.preventDefault();

    xuiSwal
      .fire({
        title: I18n.t('peer_assessment.train_samples.open_training_title'),
        text: I18n.t('peer_assessment.train_samples.open_training_message'),
        icon: 'warning',
        confirmButtonText: I18n.t('global.confirm'),
        cancelButtonText: I18n.t('global.cancel'),
      })
      .then(function (result) {
        if (result.value) {
          $('#open_training_form').off('submit').submit();
        }
      });

    return false;
  });
});
