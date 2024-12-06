window.requestAnimFrame = (function () {
  return (
    window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    function (callback) {
      window.setTimeout(callback, 1000 / 60);
    }
  );
})();

function draw_result(container_id, percentage, points) {
  var canvas = document.getElementById(container_id);
  var cxt = canvas.getContext('2d');
  var width = 200;
  var height = 200;
  var center = { x: width / 2, y: height / 2 };
  var value = percentage;
  var initialValue = 0;

  var rotation = Math.random() * Math.PI * 2;

  var draw = function () {
    rotation += 0.0; // No rotation currently (was .001)

    if (rotation >= Math.PI * 2) rotation -= Math.PI * 2;

    if (Math.abs(initialValue - value) < 0.001) initialValue = value;

    if (initialValue != value) {
      initialValue += (value - initialValue) / 50;
    }

    cxt.clearRect(0, 0, width, height);
    cxt.save();

    cxt.translate(center.x, center.y);

    cxt.font = '2em OpenSansRegular';
    cxt.textAlign = 'center';
    cxt.textBaseline = 'middle';
    cxt.fillText(points, 0, 0);

    cxt.lineWidth = 20;
    cxt.beginPath();

    var grad = cxt.createLinearGradient(0, 0, 0, height);
    grad.addColorStop(0, '#9dc420');
    grad.addColorStop(1, '#5e7725');
    cxt.strokeStyle = grad;
    cxt.stroke();

    cxt.beginPath();
    cxt.arc(0, 0, 70, rotation, Math.PI * 2 * initialValue + rotation, false);
    grad = cxt.createLinearGradient(0, 0, 0, height);
    grad.addColorStop(0, '#9dc420');
    grad.addColorStop(1, '#5e7725');
    cxt.strokeStyle = grad;

    cxt.stroke();

    cxt.restore();
    requestAnimFrame(draw);
  };

  draw();
}
