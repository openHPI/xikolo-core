ready(function () {
  $('.js-hide-rubrics').each(function (index, element) {
    $(element).click(function () {
      $($(element).data('hide')).toggleClass('hidden');

      var text = $(element).html();
      $(element).html($(element).data('alternative-text'));
      $(element).data('alternative-text', text);
    });
  });

  $('#direct-search-form').submit(function () {
    // Rewrite url
    $('#direct-search-form').attr(
      'action',
      $('#direct-search-form').attr('action') + $('#id-input').val(),
    );
    $('#id-input').attr('disabled', 'disabled'); // Prevent submit
  });
});
