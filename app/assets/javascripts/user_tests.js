$(function () {
  $(document).on('click', 'tr[data-link]', function () {
    return (window.location = $(this).data('link'));
  });

  if (!($('.box-plot').length > 0)) {
    return;
  }
  return (() => {
    const result = [];
    for (var chart of Array.from($('.box-plot'))) {
      chart = $(chart);
      var chart_data = chart.data('chart-data');
      var outliers = [];
      for (var i = 0; i < chart_data['outliers'].length; i++) {
        var item = chart_data['outliers'][i];
        for (var outlier of Array.from(item)) {
          outliers.push([i, outlier]);
        }
      }
      result.push(
        chart.highcharts({
          chart: {
            type: 'boxplot',
          },

          title: {
            text: 'Box Plot',
          },

          legend: {
            enabled: false,
          },

          xAxis: {
            categories: chart_data['groups'],
            title: {
              text: 'Experiment No.',
            },
          },

          yAxis: {
            title: {
              text: 'Observations',
            },
          },

          series: [
            {
              name: 'Observations',
              data: chart_data['data'],
              tooltip: {
                headerFormat: '<em>Experiment No {point.key}</em><br/>',
              },
            },
            {
              name: 'Outlier',
              color: Highcharts.getOptions().colors[0],
              type: 'scatter',
              data: outliers,
              marker: {
                fillColor: 'white',
                lineWidth: 1,
                lineColor: Highcharts.getOptions().colors[0],
              },

              tooltip: {
                pointFormat: 'Observation: {point.y}',
              },
            },
          ],
        }),
      );
    }
  })();
});
