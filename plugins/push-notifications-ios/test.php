<?php
/**
 * Template Name: Register Device
 * Description: The Push Notifications Page template
 */
 ?>

<?php
   // define('WP_USE_THEMES', false);

    require(dirname(__FILE__)."/../../../wp-load.php");
//    require(dirname(__FILE__)."/../../../wp-blog-header.php");
    
    if (file_exists(dirname(__FILE__)."/../../../wp-blog-header.php"))
    {
        echo "Have a blog headerss";
    }
    else
    {
        echo "NO BLOG HEADER";
    }
    echo dirname(__FILE__);

    error_log("Register device ", 3, "status.txt");

    //require dirname(__FILE__)."/../../../wp-blog-header.php";

    if ( $_GET['task'] == 'register'){
        echo "Register time?";
        
    }
    
    
    global $wpdb;
    $apns_devices = $wpdb->prefix.'pn_apns_devices';
    $apns_messages = $wpdb->prefix.'pn_apns_messages';
    
    if (isset($wpdb))
    {
        echo "haveDB";
        
        $count_posts = wp_count_posts();
        
        $published_posts = $count_posts->publish;
        echo "Num Posts ".$published_posts;
    }
    else
    {
        echo "haveNOOOOODB";
    }

http://www.thewordisbond.com/wp-content/plugins/push-notifications-ios/register_user_device.php?task=register&appname=WordIsBond&appversion=5&deviceuid=34A53B26-9F7E-439E-8586-7746F94E09AE&devicetoken=8f0ed94292cd0e2553e27e9c8040e469c445cc708258e73ddd53a2b238f5cf8d&devicename=Kristy%E2%80%99s%20iPhone&devicemodel=iPhone&deviceversion=8.0&pushbadge=enabled&pushalert=enabled&pushsound=enabled
    
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

	if ( $_GET['task'] == 'register'){
        echo "Register time?";

 	}

}else{

	echo "Where are we? :/";

}

?>