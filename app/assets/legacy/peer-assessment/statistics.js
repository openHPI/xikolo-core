/* eslint-disable no-undef */
import '../libraries/dimple';
import ready from '../../util/ready';

ready(function () {
  const peerAssessmentCharts = document.querySelectorAll(
    '[data-behavior="peer-assessment-chart"]',
  );

  peerAssessmentCharts.forEach((chart) => {
    const data = JSON.parse(chart.dataset.chartData);
    const svg = dimple.newSvg(`#${chart.id}`, '100%', '100%');
    const myPeerChart = new dimple.chart(svg, data);

    const x = myPeerChart.addTimeAxis('x', 'Date', '%Y-%m-%d', '%d-%m-%Y');
    x.addOrderRule('Date');

    myPeerChart.addMeasureAxis('y', 'Count');
    myPeerChart.addSeries('Type', dimple.plot.line);
    myPeerChart.setMargins('25px', '25px', '25px', '75px');
    myPeerChart.addLegend(60, 10, 500, 20, 'right');
    myPeerChart.draw();
  });
});
