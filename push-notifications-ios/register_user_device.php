<?php
/**
 * Template Name: Register Device
 * Description: The Push Notifications Page template
 */
 ?>
<?php

require dirname(__FILE__)."/../../../wp-blog-header.php";

echo "dance Party";


//error_log("Big trouble, we're all out of FOOs!", 1,
//               "tomberry76@hotmail.com");

echo "boogie ON";

$localdir =dirname(__FILE__);

echo $localdir;

echo "boogie UP";

error_log("Testing", 3, $localdir."/status.txt");

echo "boogie OFF";

$blogheader = $localdir."/../../../wp-blog-header.php";
//$blogheader = "/var/www/vhosts/temp-wordisbond.co/wordisbond/wp-blog-header.php";
//$blogheader = $_SERVER['DOCUMENT_ROOT']."/wp-blog-header.php";

echo $blogheader;

if (file_exists($blogheader))
{
	echo "I SEE IT";
}
else
{
	echo "I DONT SEE IT";
}

//require_once('wp-config.php');
//require_once($blogheader);

echo "boogie OUT";

//error_log("Step 2", 3, "./status.txt');

global $wpdb;
$apns_devices = $wpdb->prefix.'pn_apns_devices';
$apns_messages = $wpdb->prefix.'pn_apns_messages';

if (isset($wpdb))
{
	echo "haveDB";
}
else
{
	echo "haveNOOOOODB";
}
//error_log("Step 3", 3, dirname(__FILE__)."/status.txt');

if ( 
	isset($_GET['task'])&&
	isset($_GET['appname']) && 
	isset($_GET['appversion']) && 
	isset($_GET['deviceuid']) &&
	isset($_GET['devicetoken']) &&
	isset($_GET['devicename']) &&
	isset($_GET['devicemodel']) && 
	isset($_GET['deviceversion']) &&
	isset($_GET['pushbadge']) && 
	isset($_GET['pushalert']) && 
	isset($_GET['pushsound'])

	){

//error_log("Step 4", 3, dirname(__FILE__)."/status.txt');

	if ( $_GET['task'] == 'register'){

        $count_posts = wp_count_posts();
        
        $published_posts = $count_posts->publish;
        
        $numPosts = (int)$published_posts;

        error_log($_GET['devicename'].":".$numPosts, 3, $localdir."/status.txt");
        
		$wpdb->insert(
				$apns_devices, 
				array( 
					'appname'       =>  $_GET['appname'],
					'appversion'    =>  $_GET['appversion'],
					'deviceuid'     =>  $_GET['deviceuid'],
					'devicetoken'   =>  $_GET['devicetoken'],
					'devicename'    =>  $_GET['devicename'],
					'devicemodel'   =>  $_GET['devicemodel'],
					'deviceversion' =>  $_GET['deviceversion'],
					'pushbadge'     =>  $_GET['pushbadge'],
					'pushalert'     =>  $_GET['pushalert'],
					'pushsound'     =>  $_GET['pushsound'],
                    'seenposts'     => $numPosts
				), 
				array( 
					'%s', 
					'%s', 
					'%s', 
					'%s', 
					'%s',
					'%s', 
					'%s', 
					'%s', 
					'%s', 
                    '%s',
                    '%d'
				) 
			);

        error_log("post Insertion", 3, $localdir."/status.txt");
        
//        error_log("Insertion ret = ".$ret, 3, $localdir."/status.txt");

//        if ($ret)
//        {
//            error_log("Inserted", 3, $localdir."/status.txt");
//        }
//        else
//        {
//            error_log("Not Inserted", 3, $localdir."/status.txt");
        
        $deviceToken = $_GET['devicetoken'];
        
        $sql = "UPDATE $apns_devices SET
                seenposts = '$numPosts'
                WHERE devicetoken = '$deviceToken'";

            $wpdb->query(
                         $sql
                         );
//        }

        error_log("post query", 3, $localdir."/status.txt");

	}

}else{

	echo "Where are we? :/";

}

?>