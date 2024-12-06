ready(function () {
  if ($('#rating-wrapper:not(.rendered)').length) {
    $('.star-box .indicator').each(function (index, element) {
      $(element).click(function () {
        $('#rating').html($(element).data('value'));
        $('#rating-bar').animate(
          {
            backgroundColor: $(element).data('color'),
            width: $(element).data('fill') + '%',
          },
          500,
          function () {
            $('#rating-value').val($(element).data('value'));
          },
        );
      });
    });
  }

  if ($('#rating-wrapper.rendered').length) {
    var element = $(
      '.indicator[data-value="' + $('#rating-bar').data('rating') + '"]',
    ).first();

    $('#rating-bar').animate(
      {
        backgroundColor: $(element).data('color'),
        width: $(element).data('fill') + '%',
      },
      1000,
      function () {
        $('#rating-value').val($(element).data('value'));
      },
    );
  }
});
