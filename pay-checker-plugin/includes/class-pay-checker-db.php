<?php
if (!defined('ABSPATH')) {
    exit;
}

class Pay_Checker_DB {

    public static function create_tables() {
        global $wpdb;

        $charset_collate = $wpdb->get_charset_collate();

        $payments_table = $wpdb->prefix . 'pay_checker_payments';
        $devices_table  = $wpdb->prefix . 'pay_checker_devices';
        $logs_table     = $wpdb->prefix . 'pay_checker_logs';

        require_once(ABSPATH . 'wp-admin/includes/upgrade.php');

        // Payments Table
        $sql_payments = "CREATE TABLE $payments_table (
            id bigint(20) NOT NULL AUTO_INCREMENT,
            trx_id varchar(100) NOT NULL,
            provider varchar(50) NOT NULL,
            amount decimal(10,2) NOT NULL DEFAULT '0.00',
            sender varchar(50) DEFAULT '',
            raw_sms text DEFAULT '',
            status varchar(50) NOT NULL DEFAULT 'received',
            order_id bigint(20) DEFAULT NULL,
            device_id varchar(100) DEFAULT '',
            received_at datetime NOT NULL,
            processed_at datetime DEFAULT NULL,
            failure_reason text DEFAULT NULL,
            PRIMARY KEY  (id),
            UNIQUE KEY provider_trx (provider, trx_id),
            KEY order_id (order_id),
            KEY status (status)
        ) $charset_collate;";

        dbDelta($sql_payments);

        // Devices Table
        $sql_devices = "CREATE TABLE $devices_table (
            id bigint(20) NOT NULL AUTO_INCREMENT,
            device_id varchar(100) NOT NULL,
            device_name varchar(100) NOT NULL,
            device_model varchar(100) DEFAULT '',
            os_version varchar(50) DEFAULT '',
            device_token varchar(255) NOT NULL,
            status varchar(20) NOT NULL DEFAULT 'active',
            registered_at datetime NOT NULL,
            last_sync datetime DEFAULT NULL,
            PRIMARY KEY  (id),
            UNIQUE KEY device_id (device_id)
        ) $charset_collate;";

        dbDelta($sql_devices);

        // System Logs Table
        $sql_logs = "CREATE TABLE $logs_table (
            id bigint(20) NOT NULL AUTO_INCREMENT,
            type varchar(50) NOT NULL DEFAULT 'info',
            title varchar(255) NOT NULL,
            message text NOT NULL,
            details text DEFAULT NULL,
            created_at datetime NOT NULL,
            PRIMARY KEY  (id)
        ) $charset_collate;";

        dbDelta($sql_logs);
    }
}
