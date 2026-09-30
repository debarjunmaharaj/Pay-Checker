<?php
if (!defined('ABSPATH')) {
    exit;
}

class Pay_Checker_Logger {

    public static function log($type, $title, $message, $details = null) {
        global $wpdb;
        $table = $wpdb->prefix . 'pay_checker_logs';

        $wpdb->insert(
            $table,
            array(
                'type' => sanitize_text_field($type),
                'title' => sanitize_text_field($title),
                'message' => sanitize_text_field($message),
                'details' => is_array($details) || is_object($details) ? json_encode($details) : sanitize_text_field($details),
                'created_at' => current_time('mysql'),
            )
        );
    }

    public static function info($title, $message = '', $details = null) {
        self::log('info', $title, $message, $details);
    }

    public static function sms($title, $message = '', $details = null) {
        self::log('sms', $title, $message, $details);
    }

    public static function api($title, $message = '', $details = null) {
        self::log('api', $title, $message, $details);
    }

    public static function verification($title, $message = '', $details = null) {
        self::log('verification', $title, $message, $details);
    }

    public static function error($title, $message = '', $details = null) {
        self::log('error', $title, $message, $details);
    }
}
