/* eslint-disable no-undef */
import '../libraries/dimple';
import ready from '../../util/ready';

ready(function () {
  const submissionChart = document.getElementById('submission_chart');

  if (submissionChart) {
    const data = JSON.parse(submissionChart.dataset.chartData);

    const statData = data.map((value) => ({
      Date: new Date(value[0]),
      Value: value[1],
    }));

    const svg = dimple.newSvg('#submission_chart', '100%', '100%');

    const quizChart = new dimple.chart(svg, statData);
    quizChart.setMargins('25px', '25px', '25px', '25px');

    const x = quizChart.addCategoryAxis('x', 'Date');
    x.addOrderRule('Date');

    const y = quizChart.addMeasureAxis('y', 'Value');
    y.overrideMax = submissionChart.dataset.yMax;
    y.overrideMin = 0;
    x.hidden = true;
    quizChart.addColorAxis('Value', ['#ff0000', '#fcb913', '#8cb30d']);

    const lines = quizChart.addSeries(null, dimple.plot.line);
    lines.getTooltipText = function (e) {
      return [e.cy + ' points / ' + getRelativeTime(new Date(e.cx))];
    };
    lines.lineWeight = 4;
    lines.lineMarkers = true;

    quizChart.draw();
  }
});
