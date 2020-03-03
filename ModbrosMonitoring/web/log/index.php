<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Log</title>
</head>
<body>
<div id="container">
    <?php
    include '../constants.php';

    $base = Constants::LOG_DIR . '/log';
    $log = nl2br(file_get_contents($base . '.txt'));
    if (isset($_GET['all'])) {
        for ($i = 0; $i < 10; $i++) {
            $path = $base . '_' . $i . '.txt';
            if (file_exists($path)) {
                $log .= "<br/><br/>";
                $log .= "===========================================================================================<br />";
                $log .= "========================================= LOG " . $i . " ============================================<br />";
                $log .= "===========================================================================================<br />";
                $log .= nl2br(file_get_contents($path));
            }
        }
    }
    echo $log;
    ?>
</div>
</body>
</html>