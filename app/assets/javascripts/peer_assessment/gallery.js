ready(function () {
  $('#generate-gallery-button').click(function () {
    showLoading();
    $('#generate-error-message').addClass('hidden');
    $.get($('#generate-gallery-button').data('url'), function (data) {
      hideLoading();
      $('#generated-gallery').val(data);
      $('#gallery-modal').modal();
    }).fail(function () {
      $('#generate-error-message').removeClass('hidden');
      hideLoading();
    });
  });
});
