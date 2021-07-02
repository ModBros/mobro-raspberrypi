<?php
include '../constants.php';
include '../util.php';
?>

<!DOCTYPE HTML>
<html lang="en">
<head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8">
  <title>MoBro Screensaver Preview</title>
  <link rel="shortcut icon" href="../resources/favicon.ico" type="image/x-icon"/>

  <link href="../vendor/bootstrap.min.css" rel="stylesheet"/>

  <script src="../vendor/particle.js"></script>
  <script src="../vendor/jquery-3.6.0.min.js"></script>
  <script src="../vendor/moment.min.js"></script>
  <script src="../vendor/moment-timezone-with-data-10-years.min.js"></script>

  <style>
      body {
          margin: 0;
          font: normal 75% Arial, Helvetica, sans-serif;
      }

      canvas {
          display: block;
          vertical-align: bottom;
      }

      #particles-js {
          position: absolute;
          width: 100%;
          height: 100%;
          background-color: #000000;
          top: 0;
          left: 0;
          z-index: -100;
      }

      #date {
          color: lightgray;
          text-align: center;
          font-size: 44px;
          margin-top: 10px;
          font-family: sans-serif;
      }

      #clock {
          color: white;
          text-align: center;
          font-size: 60px;
          font-weight: bold;
          font-family: sans-serif;
      }

      hr {
          border: 1px solid grey;
      }

      .container {
          display: grid;
          height: 100vh;
      }

      .center {
          align-self: center;
          justify-self: center;
      }
  </style>
</head>
<body>

<div id="particles-js"></div>
<div class="container">
  <div class="center">
    <div id="date"></div>
    <hr>
    <div id="clock"></div>
  </div>
</div>

<script>
  particlesJS("particles-js", {
    "particles": {
      "number": {"value": 400, "density": {"enable": true, "value_area": 800}},
      "color": {"value": "#fff"},
      "shape": {
        "type": "circle",
        "stroke": {"width": 0, "color": "#000000"},
        "polygon": {"nb_sides": 5},
        "image": {"src": "img/github.svg", "width": 100, "height": 100}
      },
      "opacity": {
        "value": 0.5,
        "random": true,
        "anim": {"enable": false, "speed": 1, "opacity_min": 0.1, "sync": false}
      },
      "size": {"value": 10, "random": true, "anim": {"enable": false, "speed": 40, "size_min": 0.1, "sync": false}},
      "line_linked": {"enable": false, "distance": 500, "color": "#ffffff", "opacity": 0.4, "width": 2},
      "move": {
        "enable": true,
        "speed": 2,
        "direction": "bottom",
        "random": false,
        "straight": false,
        "out_mode": "out",
        "bounce": false,
        "attract": {"enable": false, "rotateX": 600, "rotateY": 1200}
      }
    },
    "interactivity": {
      "detect_on": "canvas",
      "events": {
        "onhover": {"enable": true, "mode": "bubble"},
        "onclick": {"enable": true, "mode": "repulse"},
        "resize": true
      },
      "modes": {
        "grab": {"distance": 400, "line_linked": {"opacity": 0.5}},
        "bubble": {"distance": 400, "size": 4, "duration": 0.3, "opacity": 1, "speed": 3},
        "repulse": {"distance": 200, "duration": 0.4},
        "push": {"particles_nb": 4},
        "remove": {"particles_nb": 2}
      }
    },
    "retina_detect": true
  });

  let timezone = 'UTC';
  <?php
  $tz = getOrDefault(parseProperties(Constants::FILE_MOBRO_CONFIG_READ)['localization_timezone'], 'UTC');
  echo "timezone = '$tz';";
  ?>

  function displayTime() {
    console.log(timezone)
    $('#date').html(moment().tz(timezone).format('dddd, D. MMMM'));
    $('#clock').html(moment().tz(timezone).format('HH:mm:ss'));
    setTimeout(displayTime, 1000);
  }

  $(document).ready(function () {
    displayTime();
  });
</script>
</body>
</html>