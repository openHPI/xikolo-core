var cancel_report, show_report_form;

ready(function () {
  $('#report_button li a').each(function () {
    $(this).click(function (e) {
      e.preventDefault();
      show_report_form($(this).data('reason'));
    });
  });
  return $('#report_cancel_button').click(function (e) {
    cancel_report();
    e.preventDefault();
  });
});

show_report_form = function (reason) {
  $('#report_form').removeClass('hidden');
  $('#xikolo_peer_assessment_conflict_reason')
    .find('option[value="' + reason + '"]')
    .attr('selected', true);
  $('#report_form textarea').focus();
};

cancel_report = function () {
  $('#report_form').addClass('hidden');
};
