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

  <script src="../vendor/jquery-3.3.1.slim.min.js"></script>
  <script src="../vendor/moment.min.js"></script>
  <script src="../vendor/moment-timezone-with-data-10-years.min.js"></script>

  <style>
    body {
      background: black;
    }

    #date {
      color: lightgray;
      text-align: center;
      font-size: 44px;
      margin-top: 10%;
      font-family: sans-serif;
    }

    #clock {
      color: white;
      text-align: center;
      font-size: 60px;
      margin-top: 20px;
      font-weight: bold;
      font-family: sans-serif;
    }

    hr {
      border: 1px solid grey;
    }
  </style>
</head>
<body>

<div class="container">
  <div id="date"></div>
  <hr>
  <div id="clock"></div>
</div>

<script type="text/javascript">
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