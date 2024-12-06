ready(function () {
  if ($('.team_evaluation').length) {
    $('.team_evaluation').each(function (_, team_evaluation_stars) {
      $(team_evaluation_stars)
        .find('.rating-stars .xi-icon')
        .each(function (index, element) {
          $(element).click(function () {
            if (
              $(team_evaluation_stars).find('.rating-value').val() ==
              $(element).data('value')
            ) {
              $(element).removeClass('fa-solid').addClass('fa-regular');

              $(element)
                .prevAll()
                .each(function (inner_index, star) {
                  $(star).removeClass('fa-solid').addClass('fa-regular');
                });

              $(element)
                .nextAll()
                .each(function (inner_index, star) {
                  $(star).removeClass('fa-solid').addClass('fa-regular');
                });

              $(team_evaluation_stars).find('.rating-value').val('');
              $(team_evaluation_stars).find('.rating-label').html('0');
            } else {
              $(element).removeClass('fa-regular').addClass('fa-solid');

              $(element)
                .prevAll()
                .each(function (inner_index, star) {
                  $(star).removeClass('fa-regular').addClass('fa-solid');
                });

              $(element)
                .nextAll()
                .each(function (inner_index, star) {
                  $(star).removeClass('fa-solid').addClass('fa-regular');
                });

              $(team_evaluation_stars)
                .find('.rating-value')
                .val($(element).data('value'));
              $(team_evaluation_stars)
                .find('.rating-label')
                .html($(element).data('label'));
            }
          });
        });
    });
  }
});
