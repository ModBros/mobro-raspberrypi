<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>MoBro Setup</title>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <link rel="shortcut icon" href="../resources/favicon.ico" type="image/x-icon"/>
  <link href="../bootstrap.min.css" rel="stylesheet"/>
  <link href="../bootstrap.min.js" rel="script">
</head>

<body>

<?php
include '../constants.php';

if ($file = fopen(Constants::KEY_FILE, "r")) {
    if (!feof($file)) {
        $key = fgets($file);
    }
    fclose($file);
}
?>

<div id="container" class="container">

    <?php include '../includes/header.php' ?>

  <div class="card mt-3">
    <div class="card-header">
      <h4>PC network name change</h4>
    </div>
    <div class="card-body">
      <div class="card-text">
        <p>
          New PC network name: <?php echo '<b>' . $key . '</b>'; ?> <br>
        </p>
        <hr>
        <p>
          If already connected to a network, the Raspberry will now try to locate the PC running the MoBro desktop
          application using the new PC network name.
        </p>
        <p>
          If not yet connected you just need to go back and configure the WiFi connection.<br>
          The just configured PC network name is saved and will automatically be used for the new WiFi connection. It's
          not necessary to configure it again unless it was changed in the desktop application on the PC.
        </p>
      </div>
    </div>
  </div>

  <div class="card mt-3">
    <div class="card-header">
      <h5>Log output</h5>
    </div>

    <div class="card-body">
      <pre>
          <?php
          if (isset($_POST['key'])) {
              $data = $_POST['key'] . "\n" . time() . "\n";
              $ret = false;
              $ret = file_put_contents(Constants::KEY_FILE, $data, LOCK_EX);
              if ($ret === false) {
                  echo('There was an error saving the PC network name!');
              } else {
                  echo "PC network name successfully saved \n($ret bytes written)\n";
              }
          } else {
              echo('Error! Missing data!');
          }
          ?>
      </pre>
    </div>
  </div>


  <a href="index.php" class="previous btn btn-primary mt-3">&laquo; Back</a>

  <hr>

    <?php include '../includes/footer.php' ?>
</div>

</body>
</html>