<?php
/**
 * @package Benarieb
 * @version 1.0
 */
/*
Plugin Name: Push Notifications iOS
Description: This plugin allows you to send Push Notifications directly from your WordPress site to your iOS app.
Author:  Amin Benarieb
Version: 0.3
License: GPLv2 or later

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/


function push_notifications_css(){

	echo '<link rel="stylesheet" type="text/css" href="'.plugins_url().'/push-notifications-ios/styles/pn_style.css'.'">';
	echo '<link rel="stylesheet" type="text/css" href="'.plugins_url().'/push-notifications-ios/styles/pn_buttons.css'.'">';
	echo '<script src="'.plugins_url().'/push-notifications-ios/script.js'.'"></script>';
}

function push_notifications_admin_pages() {
//	wp_enqueue_media();
	add_menu_page( 'iOS Push Notifications', 'iOS Push Notifications', 'manage_options', 'push_notifications', 'push_notifications_options_page', plugins_url( '/push-notifications-ios/img/icon.png' ), 40 ); 
}

/* ----------- INSTALATION ---------- */
/*----------------------------------*/

function push_notifications_install(){	
	
	global $wpdb;
	
	$table_settings = $wpdb->prefix.'pn_setting';
	$apns_devices = $wpdb->prefix.'pn_apns_devices';

	$sql =
	"
		CREATE TABLE IF NOT EXISTS `".$table_settings."` (
		  `id` int(10) NOT NULL AUTO_INCREMENT,
		  `developer_cer_path` varchar(250) NOT NULL,
		  `development_cer_pass` varchar(250) NOT NULL,
		  `production_cer_path` varchar(250) NOT NULL,
		  `production_cer_pass` varchar(250) NOT NULL,
		  `development` varchar(250) NOT NULL,
		  PRIMARY KEY (`id`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	";

	$sql2 =
	"
	CREATE TABLE `".$apns_devices."` (
	  `pid` int(9) unsigned NOT NULL auto_increment,
	  `appname` varchar(255) NOT NULL,
	  `appversion` varchar(25) default NULL,
	  `deviceuid` char(40) NOT NULL,
	  `devicetoken` char(64) NOT NULL,
	  `devicename` varchar(255) NOT NULL,
	  `devicemodel` varchar(100) NOT NULL,
	  `deviceversion` varchar(25) NOT NULL,
	  `pushbadge` enum('disabled','enabled') default 'disabled',
	  `pushalert` enum('disabled','enabled') default 'disabled',
	  `pushsound` enum('disabled','enabled') default 'disabled',
      `seenposts` int(9) unsigned default 0,
	  `development` enum('production','sandbox') character set latin1 NOT NULL default 'production',
	  `status` enum('active','uninstalled') NOT NULL default 'active',
	  `created` datetime NOT NULL,
	  `modified` timestamp NOT NULL default '0000-00-00 00:00:00' on update CURRENT_TIMESTAMP,
	  PRIMARY KEY  (`pid`),
	  UNIQUE KEY `appname` (`appname`,`deviceuid`),
	  UNIQUE KEY `devicetoken` (`devicetoken`),
	  KEY `devicename` (`devicename`),
	  KEY `devicemodel` (`devicemodel`),
	  KEY `deviceversion` (`deviceversion`),
	  KEY `pushbadge` (`pushbadge`),
	  KEY `pushalert` (`pushalert`),
	  KEY `pushsound` (`pushsound`),
      KEY `seenposts` (`seenposts`),
	  KEY `development` (`development`),
	  KEY `status` (`status`),
	  KEY `created` (`created`),
	  KEY `modified` (`modified`)
	) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Store unique devices';
	";

    $wpdb->query($sql);
    $wpdb->query($sql2);

	global $wpdb;
	$pn_setting = $wpdb->prefix.'pn_setting';

	$wpdb->insert( 
	$pn_setting, 
		array( 
			'developer_cer_path'      =>   '',
			'development_cer_pass'    =>   '',
			'production_cer_path'    =>    '',
			'production_cer_pass'    =>    '',
			'development'     =>           'development'
		), 
		array( 
			'%s', 
			'%s', 
			'%s'
		) 
	);
/*
    wp_insert_post( array(
            'post_title' => "Registation of device",
            'post_type'    => 'page',
            'post_name'     => "register_user_device", 
            'comment_status' => 'closed', 
            'ping_status' => 'closed', 
            'post_content' => '<meta http-equiv="Refresh" content="3; url=/" />',
            'post_status' => 'publish', 
        	)
    );
	
   update_post_meta(get_page_by_path("register_user_device")->ID, "_wp_page_template", 'register_user_device.php');*/
}
function push_notifications_page_template( $page_template ){
    if ( is_page( "register_user_device" ) )
        $page_template = dirname( __FILE__ ) . '/register_user_device.php';
    
    return $page_template;
}

function push_notifications_uninstall(){

	global $wpdb;
	
	$table_settings = $wpdb->prefix.'pn_setting';
	$apns_devices = $wpdb->prefix.'pn_apns_devices';

	$sql1 = "DROP TABLE  `".$table_settings."`;";
	$sql2 = "DROP TABLE  `".$apns_devices."`;";
    $wpdb->query($sql1);
    $wpdb->query($sql2);

//    wp_delete_post(get_page_by_path("register_user_device")->ID, true);
}
/*----------------------------------*/
/*----------------------------------*/
 
function push_notifications_send($pn_push_type, $json, $message, $sound, $badge, $postID){


	global $wpdb;
	$pn_setting = $wpdb->prefix.'pn_setting';
	$pn_settings =  $wpdb->get_results( $wpdb->prepare("SELECT * FROM $pn_setting WHERE id = %d", 1));
	$pn_settings = $pn_settings[0];

	$ssl_production = 'ssl://gateway.push.apple.com:2195';
	$feedback_P = 'ssl://feedback.push.apple.com:2196';
	$productionCertificate = $pn_settings->production_cer_path;


	$ssl_sandbox = 'ssl://gateway.sandbox.push.apple.com:2195';
	$sandboxCertificate = $pn_settings->developer_cer_path;
	$feedback_S = 'ssl://feedback.sandbox.push.apple.com:2196';

	$ssl; 
	$certificate;
	$passphrase;
	$feedback;

 

	if ($pn_settings->development == 'development'){

		$ssl = $ssl_sandbox;
//		$certificate = $sandboxCertificate;
		$certificate =  dirname(__FILE__)."/WIBPushComb.pem";
		$passphrase = $pn_settings->development_cer_pass;
		$feedback = $feedback_S;

	}
	else{

		$ssl = $ssl_production;
		$certificate = dirname(__FILE__)."/WIBPushProdComb.pem";
        $passphrase = $pn_settings->production_cer_pass;
		$feedback = $feedback_P;

	}

	//$attachment_id = push_notifications_get_attachment_id_from_url($certificate);

	//$certificate = get_attached_file( $attachment_id ); 


	    echo dirname(__FILE__);


	if (!file_exists($certificate)) 
{
	    echo "error".$certificate. $passphrase. $pn_settings->development ;
	    echo "The file $certificate does not exist! ".dirname(__FILE__);
}

	$ctx = stream_context_create();
	stream_context_set_option($ctx, 'ssl', 'local_cert', $certificate);
	stream_context_set_option($ctx, 'ssl', 'passphrase', $passphrase);

	$fp = stream_socket_client(
		$ssl, 
		$err, 
		$errstr, 
		60, 
		STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT, 
		$ctx
	);

	if (!$fp)
	exit("Failed to connect amarnew: $err $errstr");

	echo 'Connected to APNS';



	//$badge = str_replace('"', "", $badge);

	if ($pn_push_type != 'json' ){
		
		$body['aps'] = array(
			'alert' => $message,
			'sound' => $sound
			);

		if ((int)$postID >= 0)
		{
			$body['postID'] = (int)$postID;
		}

		$json = json_encode($body);

	}else{
		$json = stripslashes($json);
	}

	$payload = $json;

	echo $payload;

	global $wpdb;
	$apns_devices = $wpdb->prefix.'pn_apns_devices';
	$post_type = 'attorneys';
//	$devices_array = $wpdb->get_results( $wpdb->prepare ("SELECT * FROM $apns_devices", $post_type));
	$devices_array = $wpdb->get_results( "SELECT * FROM $apns_devices");

	stream_set_blocking ($fp, 0); //This allows fread() to return right away when there are no errors. But it can also miss errors during last seconds of sending, as there is a delay before error is returned. Workaround is to pause briefly AFTER sending last notification, and then do one more fread() to see if anything else is there.

    $isFirstTime = true;
    $resendAfter = -1;
    $totalDevices = count($devices_array);
    
    $invalidTokens = array();
    $numIterations = 0;
    
    while (($numIterations < 10) && (($resendAfter >= 0) || $isFirstTime))
    {
        $numIterations++;

        if ($isFirstTime == false)
        {
            //--- Disconnect and reconnect
            fclose($fp);

            $fp = stream_socket_client(
                                       $ssl,
                                       $err,
                                       $errstr,
                                       60,
                                       STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT, 
                                       $ctx
                                       );
            
            if (!$fp)
            {
                exit("Failed to reconnect amarnew: $err $errstr");
            }

            stream_set_blocking ($fp, 0); //This allows fread() to return right away when there are no errors. But it can also miss errors during last seconds of sending, as there is a delay before error is returned. Workaround is to pause briefly AFTER sending last notification, and then do one more fread() to see if anything else is there.
            
        }
        $isFirstTime = false;

        for ($i=0; $i<$totalDevices; $i++)
        {
            $id = $devices_array[$i]->pid;
            
            if ($resendAfter >= 0)
            {
                if ($id == $resendAfter)
                {
                    echo 'Sending messages after '.$resendAfter.' again';
                    $resendAfter = -1;
                }
                
                continue;
            }
            $deviceName = $devices_array[$i]->devicename;
            $deviceToken = $devices_array[$i]->devicetoken;

            //--- New style
            $frame = chr(1) . pack('n',32) . pack('H*', $deviceToken) . chr(3) . pack('n', 4) . pack('N', $id) . chr(2) . pack('n', strlen($payload)) . $payload;
            $msg = chr(2) . pack( 'N', strlen($frame)) . $frame;
            
            //--- Old style
            //		$msg = chr(0) . pack('n', 32) . pack('H*', $deviceToken) . pack('n', strlen($payload)) . $payload;

            $result = fwrite($fp, $msg, strlen($msg));

//            echo 'Sending to'.$deviceName;

            if (!$result)
            {
                echo 'Failed '.$deviceName.'('.$id.')';
                $resendAfter = $id;
            }
            else 
            {
                echo 'Sent '.$deviceName.'('.$id.')';
                echo $result;
            }
        }
        
        usleep(500000); //Pause for half a second. Note I tested this with up to a 5 minute pause,
        $error = checkAppleErrorResponse($fp);
        
        if ($error >= 0)
        {
            //--- Resend all after this one
            if (!in_array($error, $invalidTokens))
            {
                $resendAfter = $error;
                $invalidTokens[] = $resendAfter;
            }
        }
        else
        {
            $resendAfter = -1;
        }
	}

	fclose($fp);
    
    $totalInvalidTokens = count($invalidTokens);
    if ($totalInvalidTokens > 0)
    {
        echo 'Removing '.$totalInvalidTokens.' invalid tokens';
        for ($i=0; $i<$totalInvalidTokens; $i++)
        {
            $invalidTokenId = $invalidTokens[$i];
            echo 'Removing '.$invalidTokenId;
            $wpdb->delete( $apns_devices, array( 'pid' => $invalidTokenId ) );
        }
    }
}

    //FUNCTION to check if there is an error response from Apple
    //         Returns TRUE if there was and FALSE if there was not
    function checkAppleErrorResponse($fp) {

       $apple_error_response = fread($fp, 6); //byte1=always 8, byte2=StatusCode, bytes3,4,5,6=identifier(rowID). Should return nothing if OK.
       //NOTE: Make sure you set stream_set_blocking($fp, 0) or else fread will pause your script and wait forever when there is no response to be sent.

       if ($apple_error_response) {

            $error_response = unpack('Ccommand/Cstatus_code/Nidentifier', $apple_error_response); //unpack the error response (first byte 'command" should always be 8)

            if ($error_response['status_code'] == '0') {
                $error_response['status_code'] = '0-No errors encountered';

            } else if ($error_response['status_code'] == '1') {
                $error_response['status_code'] = '1-Processing error';

            } else if ($error_response['status_code'] == '2') {
                $error_response['status_code'] = '2-Missing device token';

            } else if ($error_response['status_code'] == '3') {
                $error_response['status_code'] = '3-Missing topic';

            } else if ($error_response['status_code'] == '4') {
                $error_response['status_code'] = '4-Missing payload';

            } else if ($error_response['status_code'] == '5') {
                $error_response['status_code'] = '5-Invalid token size';

            } else if ($error_response['status_code'] == '6') {
                $error_response['status_code'] = '6-Invalid topic size';

            } else if ($error_response['status_code'] == '7') {
                $error_response['status_code'] = '7-Invalid payload size';

            } else if ($error_response['status_code'] == '8') {
                $error_response['status_code'] = '8-Invalid token';

            } else if ($error_response['status_code'] == '255') {
                $error_response['status_code'] = '255-None (unknown)';

            } else {
                $error_response['status_code'] = $error_response['status_code'].'-Not listed';

            }

            echo '<br><b>+ + + + + + ERROR</b> Response Command:<b>' . $error_response['command'] . '</b>&nbsp;&nbsp;&nbsp;Identifier:<b>' . $error_response['identifier'] . '</b>&nbsp;&nbsp;&nbsp;Status:<b>' . $error_response['status_code'] . '</b><br>';
            echo 'Identifier is the rowID (index) in the database that caused the problem, and Apple will disconnect you from server. To continue sending Push Notifications, just start at the next rowID after this Identifier.<br>';
           
           if ($error_response['status_code'] != '0')
           {
               return $error_response['identifier'];
           }

//            return true;
       }
	else
	{
            echo 'No response from the Apple Server';
	}

       return -1;
    }

function check_feedback()
{
    global $wpdb;
    $pn_setting = $wpdb->prefix.'pn_setting';
    $pn_settings =  $wpdb->get_results( $wpdb->prepare("SELECT * FROM $pn_setting WHERE id = %d", 1));
    $pn_settings = $pn_settings[0];

    
    $ssl_production = 'ssl://gateway.push.apple.com:2195';
    $feedback_P = 'ssl://feedback.push.apple.com:2196';
    $productionCertificate = $pn_settings->production_cer_path;
    
    $ssl_sandbox = 'ssl://gateway.sandbox.push.apple.com:2195';
    $sandboxCertificate = $pn_settings->developer_cer_path;
    $feedback_S = 'ssl://feedback.sandbox.push.apple.com:2196';

    $ssl;
    $certificate;
    $passphrase;
    $feedback;
    
    if ($pn_settings->development == 'development'){
        
        $ssl = $ssl_sandbox;
        //		$certificate = $sandboxCertificate;
        $certificate =  dirname(__FILE__)."/WIBPushComb.pem";
        $passphrase = $pn_settings->development_cer_pass;
        $feedback = $feedback_S;
        
    }
    else{
        
        $ssl = $ssl_production;
        $certificate = dirname(__FILE__)."/WIBPushProdComb.pem";
        $passphrase = $pn_settings->production_cer_pass;
        $feedback = $feedback_P;
        
    }

	if (!file_exists($certificate)) 
	{
	    echo "error".$certificate. $passphrase. $pn_settings->development ;
	    echo "The file $certificate does not exist! ".dirname(__FILE__);
	}

	$ctx = stream_context_create();
	stream_context_set_option($ctx, 'ssl', 'local_cert', $certificate);
	stream_context_set_option($ctx, 'ssl', 'passphrase', $passphrase);

	$fp = stream_socket_client(
		$feedback, 
		$err, 
		$errstr, 
		2, 
		STREAM_CLIENT_CONNECT, 
		$ctx
	);

	if (!$fp)
	exit("Failed to connect to APNS: $err $errstr");

	echo 'Connected to APNS';

    $feedback_tokens = array();
    //and read the data on the connection:
    while(!feof($fp)) {
        $data = fread($fp, 38);
        if(strlen($data)) {
            $feedback_tokens[] = unpack("N1timestamp/n1length/H*devtoken", $data);
        }
    }
    echo 'readData (';
    var_dump($feedback_tokens);
    echo ') end readData';
//	$result = fread($fp, 38);
//    	echo 'result= ' . $result;
 }
    
function list_users()
{
    global $wpdb;
    $apns_devices = $wpdb->prefix.'pn_apns_devices';
    $devices_array = $wpdb->get_results( "SELECT * FROM $apns_devices");

    echo "<table style='width:100%'>";

    echo "<tr>";
    echo "<td> ID </td>";
    echo "<td> Name </td>";
    echo "<td> UID </td>";
    echo "<td> version </td>";
    echo "<td> seen posts </td>";
    echo "<td> badge </td>";
    echo "<td> alert </td>";
    echo "<td> Token </td>";
    echo "</tr>";

    for ($i=0; $i!=count($devices_array); $i++)
    {
        $deviceToken = $devices_array[$i]->devicetoken;
        $deviceName = $devices_array[$i]->devicename;
        $appversion = $devices_array[$i]->appversion;
        $deviceUID = $devices_array[$i]->deviceuid;
        $seenposts = $devices_array[$i]->seenposts;
        $pushBadge = $devices_array[$i]->pushbadge;
        $pushAlert = $devices_array[$i]->pushalert;
        $pid = $devices_array[$i]->pid;

        echo "<tr>";
        echo "<td>".$pid."</td>";
        echo "<td>".$deviceName."</td>";
        echo "<td>".$deviceUID."</td>";
        echo "<td>".$appversion."</td>";
        echo "<td>".$seenposts."</td>";
        echo "<td>".$pushBadge."</td>";
        echo "<td>".$pushAlert."</td>";
        echo "<td>".$deviceToken."</td>";
        echo "</tr>";
    }
    echo "</table>";
}

/*----------------------------------*/
/*----------------------------------*/

function push_notifications_logo(){


	echo "<img width='50' hegiht='50' src='".plugins_url()."/push-notifications-ios/img/logo.png'/>";
}

/*----------------------------------*/
/*----------------------------------*/

function push_notifications_devices(){

	global $wpdb;

	$apns_devices = $wpdb->prefix.'pn_apns_devices';
	$devices_count = $wpdb->get_var("SELECT COUNT(*) FROM $apns_devices");

	echo "
	<div id='devices'>
	<h2>Devices</h2>"
	.__("Count of devices: ")."<b>".$devices_count."</b>
	</div>
	";

/*

	$devices_array = $wpdb->get_results( $wpdb->prepare ("SELECT * FROM $apns_devices", 0));

	echo "<div>“;
	for ($i=0; $i!=count($devices_array); $i++)
	{ 
		$deviceName = $devices_array[$i]->devicename;
		$deviceModel = $devices_array[$i]->devicemodel;
	   	echo “<p>”.$deviceName.” of type ”.$deviceModel.”</p>”;
	}

	echo "</div>“;
*/
}

/*----------------------------------*/
/*----------------------------------*/

function push_notifications_change_settigs(){	

	global $wpdb;
	$pn_setting = $wpdb->prefix.'pn_setting';

	if (isset($_POST['push_notifications_setup_btn'])) 
	{   
	   if ( function_exists('current_user_can') && 
			!current_user_can('manage_options') )
				die ( _e('Hacker?', 'push_notifications') );

		if (function_exists ('check_admin_referer') )
			check_admin_referer('push_notifications_setup_form');

	
		$developer_cer_path = $_POST['upload_developer_cer'];
		$production_cer_path = $_POST['upload_production_cer'];

		$production_cer_pass = $_POST['production_cer_pass'];
		$development_cer_pass = $_POST['development_cer_pass'];

		$development = $_POST['development'];

		$sql = "UPDATE $pn_setting SET 
			developer_cer_path = '$developer_cer_path', 
			development_cer_pass = '$development_cer_pass',
			production_cer_path = '$production_cer_path',
			production_cer_pass = '$production_cer_pass',
			development = '$development' 
			WHERE id = 1";

		$wpdb->query($sql);


	}

	$pn_settings =  $wpdb->get_results( $wpdb->prepare("SELECT * FROM $pn_setting WHERE id = %d", 1));
	$pn_settings = $pn_settings[0];

	$development = ($pn_settings->development == 'development') ? 'checked' : '';
	$production =  ($pn_settings->development == 'production')  ? 'checked' : '';


	echo
		"
			<div id='pn_settings'>
		   <h2>Settings:</h2>
			<form name='push_notifications_setup' method='post' action='".$_SERVER['PHP_SELF']."?page=push_notifications&amp;updated=true'>
		";

		if (function_exists ('wp_nonce_field') )
			wp_nonce_field('push_notifications_setup_form'); 
	echo
		"			<label><input $development class='pn_radio' type='radio' checked name='development' value='development'><span class='overlay'></span></label>
					<p><label for='upload_cer'  class='uploader' id='upload_developer_cer'>
						<input type='password' name='development_cer_pass' value='$pn_settings->development_cer_pass'  placeholder='Password Development'/>
						<input class='upload_cer' type='text' name='upload_developer_cer' value='$pn_settings->developer_cer_path' placeholder='Сертификат Development' >
						<a class='pn_button attachment has-icon'><i class='icon-attachment'>Upload Certificate</i></a>
					</label>
					</p>
					<label><input $production class='pn_radio' type='radio' name='development' value='production'><span class='overlay'></span></label>
					<p>
					<label for='upload_cer'  class='uploader' id='upload_production_cer'>
						<input type='password' name='production_cer_pass'  value='$pn_settings->production_cer_pass' placeholder='Password Production'/>
						<input class='upload_cer' type='text' name='upload_production_cer' value='$pn_settings->production_cer_path'  placeholder='Сертификат Production'>
						<a class='pn_button attachment has-icon'><i class='icon-attachment'>Upload Certificate</i></a>
					</label></p>
						<input type='submit' name='push_notifications_setup_btn' class='pn pn_button' value='Save' />
			</form>
			</div>
		";
}

/*----------------------------------*/
/*----------------------------------*/

function push_notifications_create_form(){


	if (isset($_POST['push_notifications_push_btn'])) 
	{   
	   if ( function_exists('current_user_can') && 
			!current_user_can('manage_options') )
				die ( _e('Hacker?', 'push_notifications') );

		if (function_exists ('check_admin_referer') )
			check_admin_referer('push_notifications_form');


		push_notifications_send(
			$_POST['pn_push_type'],
			$_POST['json'],
			$_POST['pn_text'],
			$_POST['pn_sound'],
			$_POST['pn_badge'],
			$_POST['pn_postID']
			);


	}
    if (isset($_POST['push_notifications_pushpost_btn']))
    {
        if ( function_exists('current_user_can') &&
            !current_user_can('manage_options') )
            die ( _e('Hacker?', 'push_notifications') );
        
        if (function_exists ('check_admin_referer') )
            check_admin_referer('push_notifications_form');
        
        $post = get_post($_POST['pn_postID']);
        on_new_post( 'publish', 'draft', $post );
    }
	if (isset($_POST['push_notifications_feedback_push_btn']))
	{   
	   if ( function_exists('current_user_can') && 
			!current_user_can('manage_options') )
				die ( _e('Hacker?', 'push_notifications') );

		if (function_exists ('check_admin_referer') )
			check_admin_referer('push_notifications_form');

		check_feedback();
	}
    if (isset($_POST['push_notifications_users_push_btn']))
    {
        if ( function_exists('current_user_can') &&
            !current_user_can('manage_options') )
            die ( _e('Hacker?', 'push_notifications') );
        
        if (function_exists ('check_admin_referer') )
            check_admin_referer('push_notifications_form');
        
        list_users();
    }
    if (isset($_POST['push_notifications_badge_push_btn']))
    {
        if ( function_exists('current_user_can') &&
            !current_user_can('manage_options') )
            die ( _e('Hacker?', 'push_notifications') );
        
        if (function_exists ('check_admin_referer') )
            check_admin_referer('push_notifications_form');
        
//        on_new_post(2);
    }

	echo
		"<div id='pn_form'>
	        <h2>Create push notification</h2>
			<form id='push_form' name='push_notifications' method='post' action='".$_SERVER['PHP_SELF']."?page=push_notifications&amp;updated=true'>
		";
		
		if (function_exists ('wp_nonce_field') )
			wp_nonce_field('push_notifications_form'); 
		?>
						<div id="output"></div>
						<div>
							<label><input class='pn_radio' type='radio' checked name='pn_push_type' value='default'><span class='overlay'></span></label>
							<p><input type='text' name='pn_text'   placeholder='Text' /></p>
							<p><input type='text' name='pn_sound'  placeholder='Sound' value=''/></p>
							<p><input type='text' name='pn_badge'  placeholder='Badge (number)' value='1' /></p>
                            <label for="PostID"> Linked Post ID (set to the number of a post to hotlink the app to that post):</label>
                            <p><input type='text' name='pn_postID' id="PostID" placeholder='PostID (number)' value='-1' /></p>
							<label><input class='pn_radio' type='radio' name='pn_push_type' value='json'><span class='overlay'></span></label>
							<p><textarea type='text' name='json' placeholder='JSON'>{ "aps": { "badge": 1, "alert": "Hello world!"}, "action": "" }</textarea></p>
						</div>
						<div>
							<input type='submit' id="push_button" class='pn blue push_button' name='push_notifications_push_btn' value='Send' />
						</div>
                        <div>
                            <input type='submit' id="push_button" class='pn blue push_button' name='push_notifications_pushpost_btn' value='SendPost' />
                        </div>
						<div>
							<input type='submit' id="push_button" class='pn blue push_button' name='push_notifications_feedback_push_btn' value='Feedback' />
						</div>
                        <div>
                            <input type='submit' id="push_button" class='pn blue push_button' name='push_notifications_users_push_btn' value='List Users' />
                        </div>
                        <div>
                            <input type='submit' id="push_button" class='pn blue push_button' name='push_notifications_badge_push_btn' value='Update Badges' />
                        </div>
			</form>
			</div>
		<?php
}

/*----------------------------------*/
/*----------------------------------*/

function push_notifications_options_page() {

	echo"<center><div id='apns' class='apns_block' >
	<a class='pn_button has-icon help'><i class='icon-help'>Help</i></a>";
	push_notifications_logo();
	push_notifications_devices();
	push_notifications_change_settigs();
	push_notifications_create_form();
	echo "</div></center>";
}

/*----------------------------------*/
/*----------------------------------*/
function add_custom_upload_mimes($existing_mimes){

	$existing_mimes['pem'] = 'application/octet-stream';

	return $existing_mimes;

}

/*----------------------------------*/

function push_notifications_get_attachment_id_from_url( $attachment_url = '' ) {
 
	global $wpdb;
	$attachment_id = false;
 
	// If there is no url, return.
	if ( '' == $attachment_url )
		return;
 
	// Get the upload directory paths
	$upload_dir_paths = wp_upload_dir();
 
	// Make sure the upload path base directory exists in the attachment URL, to verify that we're working with a media library image
	if ( false !== strpos( $attachment_url, $upload_dir_paths['baseurl'] ) ) {
 
		// If this is the URL of an auto-generated thumbnail, get the URL of the original image
		$attachment_url = preg_replace( '/-\d+x\d+(?=\.(jpg|jpeg|png|gif)$)/i', '', $attachment_url );
 
		// Remove the upload path base directory from the attachment URL
		$attachment_url = str_replace( $upload_dir_paths['baseurl'] . '/', '', $attachment_url );
 
		// Finally, run a custom database query to get the attachment ID from the modified attachment URL
		$attachment_id = $wpdb->get_var( $wpdb->prepare( "SELECT wposts.ID FROM $wpdb->posts wposts, $wpdb->postmeta wpostmeta WHERE wposts.ID = wpostmeta.post_id AND wpostmeta.meta_key = '_wp_attached_file' AND wpostmeta.meta_value = '%s' AND wposts.post_type = 'attachment'", $attachment_url ) );
 
	}
 
	return $attachment_id;
}

/*----------------------------------*/
            
function notify_new_post($post_id) {
   //if( ( $_POST['post_status'] == 'publish' ) && ( $_POST['original_post_status'] != 'publish' ) )
   {
          $post = get_post($post_id);
          $author = get_userdata($post->post_author);
          $email_subject = "Your post has been published.";
                    
                    ob_start(); ?>

<html>
<head>
<title>New post at <?php bloginfo( 'name' ) ?></title>
</head>
<body>
<p>
Hi <?php echo $author->user_firstname ?>,
</p>
<p>
Your post <a href="<?php echo get_permalink($post->ID) ?>"><?php the_title_attribute() ?></a> has been published.
</p>
</body>
</html>

<?php
    
    $message = ob_get_contents();
    
    ob_end_clean();
    
    wp_mail( "tomberry76@hotmail.com", $email_subject, $message );
    }
    }


    function on_new_post($new_status, $old_status, $post)
    {
        if ( 'publish' !== $new_status or 'publish' === $old_status )
            return;

        if ( 'post' !== $post->post_type )
            return; // restrict the filter to a specific post type
        
        $post_id = $post->ID;
        
        $count_posts = wp_count_posts();
        
        $published_posts = $count_posts->publish;
        
        $numPosts = (int)$published_posts;
        
        $encoded_title = get_the_title($post_id);
        $new_post_title = html_entity_decode($encoded_title, ENT_NOQUOTES, 'UTF-8');//mb_convert_encoding($encoded_title, "ASCII", "auto");
        
        
        global $wpdb;
        $pn_setting = $wpdb->prefix.'pn_setting';
        $pn_settings =  $wpdb->get_results( $wpdb->prepare("SELECT * FROM $pn_setting WHERE id = %d", 1));
        $pn_settings = $pn_settings[0];
        
        
        $ssl_production = 'ssl://gateway.push.apple.com:2195';
        $feedback_P = 'ssl://feedback.push.apple.com:2196';
        $productionCertificate = $pn_settings->production_cer_path;
        
        $ssl_sandbox = 'ssl://gateway.sandbox.push.apple.com:2195';
        $sandboxCertificate = $pn_settings->developer_cer_path;
        $feedback_S = 'ssl://feedback.sandbox.push.apple.com:2196';
        
        $ssl;
        $certificate;
        $passphrase;
        $feedback;
        
        if ($pn_settings->development == 'development'){
            
            $ssl = $ssl_sandbox;
            //		$certificate = $sandboxCertificate;
            $certificate =  dirname(__FILE__)."/WIBPushComb.pem";
            $passphrase = $pn_settings->development_cer_pass;
            $feedback = $feedback_S;
            
        }
        else{
            
            $ssl = $ssl_production;
            $certificate = dirname(__FILE__)."/WIBPushProdComb.pem";
            $passphrase = $pn_settings->production_cer_pass;
            $feedback = $feedback_P;
            
        }
        
        //$attachment_id = push_notifications_get_attachment_id_from_url($certificate);
        
        //$certificate = get_attached_file( $attachment_id );
        
        
        echo dirname(__FILE__);
        
        
        if (!file_exists($certificate))
        {
            echo "error".$certificate. $passphrase. $pn_settings->development ;
            echo "The file $certificate does not exist! ".dirname(__FILE__);
        }
        
        $ctx = stream_context_create();
        stream_context_set_option($ctx, 'ssl', 'local_cert', $certificate);
        stream_context_set_option($ctx, 'ssl', 'passphrase', $passphrase);
        
        $fp = stream_socket_client(
                                   $ssl,
                                   $err,
                                   $errstr,
                                   60,
                                   STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT,
                                   $ctx
                                   );
        
        if (!$fp)
            exit("Failed to connect amarnew: $err $errstr");

        echo 'Connected to APNS';

        stream_set_blocking ($fp, 0); //This allows fread() to return right away when there are no errors. But it can also miss errors during last seconds of sending, as there is a delay before error is returned. Workaround is to pause briefly AFTER sending last notification, and then do one more fread() to see if anything else is there.
        
        
        $body['aps'] = array(
                             'badge' => $numPosts
                             );
        
        if ((int)$post_id >= 0)
        {
            $body['postID'] = (int)$post_id;
        }
        
        $json = json_encode($body);
        
        $payload = $json;
        
        echo $payload;
        
        global $wpdb;
        $apns_devices = $wpdb->prefix.'pn_apns_devices';
        $devices_array = $wpdb->get_results( $wpdb->prepare ("SELECT * FROM $apns_devices", 0));
        
        $isFirstTime = true;
        $resendAfter = -1;
        $totalDevices = count($devices_array);
        
        $invalidTokens = array();
        $numIterations = 0;

        while (($numIterations < 10) && (($resendAfter >= 0) || $isFirstTime))
        {
            $numIterations++;
            
            if ($isFirstTime == false)
            {
                //--- Disconnect and reconnect
                fclose($fp);
                
                $fp = stream_socket_client(
                                           $ssl,
                                           $err,
                                           $errstr,
                                           60,
                                           STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT,
                                           $ctx
                                           );
                
                if (!$fp)
                {
                    exit("Failed to reconnect amarnew: $err $errstr");
                }
                
                stream_set_blocking ($fp, 0); //This allows fread() to return right away when there are no errors. But it can also miss errors during last seconds of sending, as there is a delay before error is returned. Workaround is to pause briefly AFTER sending last notification, and then do one more fread() to see if anything else is there.
                
            }
            $isFirstTime = false;

            for ($i=0; $i!=$totalDevices; $i++)
            {
                $id = $devices_array[$i]->pid;
                
                if ($resendAfter >= 0)
                {
                    if ($id == $resendAfter)
                    {
                        echo 'Sending messages after '.$resendAfter.' again';
                        $resendAfter = -1;
                    }
                    
                    continue;
                }
                
                $deviceToken = $devices_array[$i]->devicetoken;
                $lastPostCount = $devices_array[$i]->seenposts;
                
                $body['aps'] = array(
                                     'badge' => $numPosts-$lastPostCount,
                                     'alert' => $new_post_title,
                                     'content-available' => '1'
                                     );
                
                $json = json_encode($body);
                $payload = $json;

                
                //--- New style
                $frame = chr(1) . pack('n',32) . pack('H*', $deviceToken) . chr(3) . pack('n', 4) . pack('N', $id) . chr(2) . pack('n', strlen($payload)) . $payload;
                $msg = chr(2) . pack( 'N', strlen($frame)) . $frame;
                
                //--- Old style
                //$msg = chr(0) . pack('n', 32) . pack('H*', $deviceToken) . pack('n', strlen($payload)) . $payload;
                
                $result = fwrite($fp, $msg, strlen($msg));
                
                if (!$result)
                    echo 'Message not delivered';
                else
                    echo 'Message successfully delivered';
            }
            
            usleep(500000); //Pause for half a second. Note I tested this with up to a 5 minute pause,
            $error = checkAppleErrorResponse($fp);
            
            if ($error >= 0)
            {
                //--- Resend all after this one
                if (!in_array($error, $invalidTokens))
                {
                    $resendAfter = $error;
                    $invalidTokens[] = $resendAfter;
                }
            }
            else
            {
                $resendAfter = -1;
            }
            
        }
        
        fclose($fp);
        
        $totalInvalidTokens = count($invalidTokens);
        if ($totalInvalidTokens > 0)
        {
            echo 'Removing '.$totalInvalidTokens.' invalid tokens';
            for ($i=0; $i<$totalInvalidTokens; $i++)
            {
                $invalidTokenId = $invalidTokens[$i];
                echo 'Removing '.$invalidTokenId;
//                $wpdb->delete( $apns_devices, array( 'pid' => $invalidTokenId ) );
            }
        }
        
    }


    
    add_action( 'transition_post_status', 'on_new_post', 10, 3 );
/*----------------------------------*/
/*----------------------------------*/


register_activation_hook( __FILE__, 'push_notifications_install');
register_deactivation_hook( __FILE__, 'push_notifications_uninstall');

add_filter( 'page_template', 'push_notifications_page_template' );
add_filter('upload_mimes', 'add_custom_upload_mimes');

add_action('admin_head', 'push_notifications_css');
add_action('admin_menu', 'push_notifications_admin_pages');



?>