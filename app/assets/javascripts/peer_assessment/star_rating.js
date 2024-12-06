ready(function () {
  if ($('#rating-stars:not(.rendered)').length) {
    $('#rating-stars .xi-icon').each(function (index, element) {
      $(element).click(function () {
        if ($(element).data('value') == '1') {
          if ($(element).hasClass('fa-solid')) {
            if ($('#rating-stars .xi-icon.fa-solid').length > 1) {
              $(element)
                .nextAll()
                .each(function (inner_index, star) {
                  $(star).removeClass('fa-solid').addClass('fa-regular');
                });
              $('#rating-value').val(1);
              $('#rating').html(1);
            } else {
              $(element).removeClass('fa-solid').addClass('fa-regular');
              $('#rating-value').val(0);
              $('#rating').html(0);
            }
          } else {
            $(element).removeClass('fa-regular').addClass('fa-solid');
            $('#rating-value').val(1);
            $('#rating').html(1);
          }
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

          $('#rating-value').val($(element).data('value'));
          $('#rating').html($(element).data('value'));
        }
      });
    });
  }
});
