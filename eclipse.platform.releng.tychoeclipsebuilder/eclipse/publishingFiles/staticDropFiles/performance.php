<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" href="http://download.eclipse/eclipse/default_style.css"
  type="text/css">
<title>Performance Results</title>
</head>
<body>
 <div class="homeitem3col">
<h2 name="PerformanceResults">Performance Results</h2> 
<h3 name="Performancefingerprint">Performance fingerprint</h3>

<?php

include("../buildproperties.php");
include ("../testConfigs.php");

    $performanceDir=".";
    $performance = dir($performanceDir);
    $index=0;
    $fpcount=0;

    $fp_file="$performanceDir/global_fp.php";
    if (file_exists($fp_file)) {
        include($fp_file);
    }
    while ($file = $performance->read()) {
        if (strstr($file,".php")){
            $parts=split(".php",$file);
            $component=$parts[0];
            $start=substr($component, 0, 11);
            if ($start == "org.eclipse") {
                $componentFps[$fpcount]=$file;
                $fpcount++;
            }
        }
    }
?>
  <p>
    <a name="unit"></a>Legend: <br/>*: Missing reference data. Build used for
    comparison specified in ending parenthesis.<br>green: faster,
    less memory <br>red: slower, more memory <br>grey:
    regression with explanation. Click the bar for notes on this
    scenario. <br>x axis: difference between current value and
    baseline value as percentage<br>
  </p>

<h3 name="ScenarioDetail">Detailed performance data grouped by scenario prefix</h3>

  <?php

    if (count($componentFps)==0){
        echo "Results pending.";
    }
    else {
        $type=$_SERVER['QUERY_STRING'];
        if ($type=="") {
            $type="fp_type=0";
        }
        sort($componentFps);

        for ($counter=0;$counter<count($componentFps);$counter++){
            $parts=split(".php",$componentFps[$counter]);
            $prefix=$parts[0];
            $href="<A HREF=\"$performanceDir/$componentFps[$counter]?";
            $href=$href . $type . "\">$prefix*</A><br>";
            echo $href;
        }
    }
?>

<h3 name="UnitTest">Performance Unit Test Results for <?php echo "$BUILD_ID"; ?> </h3>

<p>The table shows the unit test results for this build on the platforms
tested. You may access the test results page specific to each
component on a specific platform by clicking the cell link.
Normally, the number of errors is indicated in the cell.
A "-1" or "DNF" means the test "Did Not Finish" for unknown reasons
and hence no results page is available. In that case,
more information can sometimes be found in
the <a href="../perflogs.php#console">console logs</a>.</p>
<?php
if (file_exists("$performanceDir/testNotes.html")) {
    $my_file = file_get_contents("$performanceDir/testNotes.html");
    echo $my_file;
}
if (file_exists("../baseline.php")) {
   echo "<p>See also the <a href=\"../baseline.php\">baseline unit tests results</a>.</p>";
}
?>



<table width="85%" border="1" bgcolor="#EEEEEE" rules="groups" align="center">
<tr bgcolor="#9999CC">
<th rowspan="2" width="40%" align="center"> org.eclipse <br> Component </th>
<th colspan="5" align="center"> Test Configurations </th></tr>
<tr bgcolor="#9999CC">
<!-- The order of the columns is "hard coded". Linux, Mac, Windows -->
<th width="20%"><?= $expectedTestConfigs[0] ?></th>
<th width="20%"><?= $expectedTestConfigs[1] ?></th>
<th width="20%"><?= $expectedTestConfigs[2] ?></th>
<th><th width="20%"></th>
</tr>

<?php
$rowResultsFile="performanceTables.html";
  if (file_exists($rowResultsFile)) {
    include $rowResultsFile;
} else {
    include "testResultsTablesPending.html";
}
?>
</table>
</div>

</body>
</html>