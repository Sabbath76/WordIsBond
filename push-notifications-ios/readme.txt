=== Push Notification iOS ===
Contributors: zedamin
Tags: push notifications, iOS, iPhone, iPad, iPod Touch
Requires at least: 3.6
Tested up to: 3.7.1
Stable tag: 0.3
License: GPLv2 or later
License URI: http://www.gnu.org/licenses/gpl-2.0.html

This plugin allows you to send Push Notifications directly from your WordPress site to your iOS app.

== Description ==

This plugin allows you to send notifications directly from your WordPress site with payload (JSON) to all devices, that have installed your app to notify users about something new.

Now, go to Installation section to find out how to install and use plugin. 


== Installation ==

This section describes how to install the plugin and get it working.


1. Upload `push_notifications_ios` to the `/wp-content/plugins/` directory
2. Activate the plugin through the 'Plugins' menu in WordPress
3. Plugin creates two tables: first for list of devises, second for settings
4. Upload your .pem certificates (if you don't know to create them follow link http://stackoverflow.com/questions/1762555/creating-pem-file-for-apns#_=_)
5. Then you need to write some lines of code in your ios app, follow link https://bitbucket.org/zedamin/push-notifications-ios/wiki/Home
7. Enjoy!

== Changelog ==

= 0.2 =
First beta version.