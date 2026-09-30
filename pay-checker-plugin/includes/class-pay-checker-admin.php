<?php
if (!defined('ABSPATH')) {
    exit;
}

class Pay_Checker_Admin {

    public static function init() {
        add_action('admin_menu', array(__CLASS__, 'add_admin_menu'));
        add_action('admin_init', array(__CLASS__, 'register_settings'));
        add_action('add_meta_boxes', array(__CLASS__, 'add_order_meta_box'));
    }

    public static function add_order_meta_box() {
        $screen = function_exists('wc_get_page_screen_id') ? wc_get_page_screen_id('shop-order') : 'shop_order';
        add_meta_box(
            'pay_checker_order_details_box',
            '💳 Pay Checker - Payment Verification Info',
            array(__CLASS__, 'render_order_meta_box'),
            $screen,
            'side',
            'high'
        );
    }

    public static function render_order_meta_box($post_or_order) {
        $order = is_a($post_or_order, 'WC_Order') ? $post_or_order : wc_get_order($post_or_order->ID);
        if (!$order) return;

        global $wpdb;

        $provider = $order->get_meta('_pay_checker_provider');
        $sender   = $order->get_meta('_pay_checker_sender');
        $trx_id   = $order->get_meta('_pay_checker_trx_id');
        $verified = $order->get_meta('_pay_checker_verified');
        $verified_at = $order->get_meta('_pay_checker_verified_at');

        $is_verified = ($verified === 'yes' || $order->is_paid());
        $status_color = $is_verified ? '#10b981' : '#f59e0b';
        $status_label = $is_verified ? 'Verified & Paid' : 'Verification Pending';

        $payments_table = $wpdb->prefix . 'pay_checker_payments';
        $payment_row = null;
        if (!empty($trx_id)) {
            $payment_row = $wpdb->get_row($wpdb->prepare("SELECT * FROM $payments_table WHERE trx_id = %s", $trx_id));
        }

        echo '<div style="font-size:13px; line-height:1.6;">';
        echo '<p style="margin-bottom:8px;"><strong>Status:</strong> <span style="background:' . $status_color . '; color:#ffffff; padding:2px 8px; border-radius:12px; font-weight:bold; font-size:11px;">' . esc_html($status_label) . '</span></p>';
        echo '<p style="margin-bottom:6px;"><strong>Payment Method:</strong> ' . esc_html(strtoupper($provider ? $provider : 'N/A')) . '</p>';
        echo '<p style="margin-bottom:6px;"><strong>Sender Number:</strong> ' . esc_html($sender ? $sender : 'N/A') . '</p>';
        echo '<p style="margin-bottom:6px;"><strong>TrxID:</strong> <code style="font-weight:bold; background:#f1f5f9; padding:2px 6px; border-radius:4px;">' . esc_html($trx_id ? $trx_id : 'N/A') . '</code></p>';
        echo '<p style="margin-bottom:6px;"><strong>Order Total:</strong> ৳' . esc_html($order->get_total()) . '</p>';

        if ($payment_row) {
            echo '<hr style="margin:10px 0; border:0; border-top:1px solid #e2e8f0;">';
            echo '<p style="margin-bottom:6px;"><strong>SMS Amount Received:</strong> ৳' . esc_html($payment_row->amount) . '</p>';
            echo '<p style="margin-bottom:6px;"><strong>Received At:</strong> ' . esc_html($payment_row->received_at) . '</p>';
            if (!empty($payment_row->device_id)) {
                echo '<p style="margin-bottom:6px;"><strong>Device ID:</strong> <code>' . esc_html($payment_row->device_id) . '</code></p>';
            }
        } elseif ($verified_at) {
            echo '<p style="margin-bottom:6px;"><strong>Verified At:</strong> ' . esc_html($verified_at) . '</p>';
        }

        echo '</div>';
    }

    public static function add_admin_menu() {
        add_menu_page(
            'Pay Checker',
            'Pay Checker',
            'manage_options',
            'pay-checker',
            array(__CLASS__, 'render_dashboard_page'),
            'dashicons-shield-alt',
            56
        );

        add_submenu_page(
            'pay-checker',
            'Dashboard',
            'Dashboard',
            'manage_options',
            'pay-checker',
            array(__CLASS__, 'render_dashboard_page')
        );

        add_submenu_page(
            'pay-checker',
            'Payments History',
            'Payments',
            'manage_options',
            'pay-checker-payments',
            array(__CLASS__, 'render_payments_page')
        );

        add_submenu_page(
            'pay-checker',
            'Devices',
            'Devices',
            'manage_options',
            'pay-checker-devices',
            array(__CLASS__, 'render_devices_page')
        );

        add_submenu_page(
            'pay-checker',
            'Settings',
            'Settings',
            'manage_options',
            'pay-checker-settings',
            array(__CLASS__, 'render_settings_page')
        );

        add_submenu_page(
            'pay-checker',
            'System Logs',
            'Logs',
            'manage_options',
            'pay-checker-logs',
            array(__CLASS__, 'render_logs_page')
        );
    }

    public static function register_settings() {
        register_setting('pay_checker_options_group', 'pay_checker_settings');
    }

    public static function render_dashboard_page() {
        global $wpdb;

        $payments_table = $wpdb->prefix . 'pay_checker_payments';
        $devices_table  = $wpdb->prefix . 'pay_checker_devices';

        $total_payments = $wpdb->get_var("SELECT COUNT(*) FROM $payments_table");
        $verified_count = $wpdb->get_var("SELECT COUNT(*) FROM $payments_table WHERE status = 'verified'");
        $unmatched_count = $wpdb->get_var("SELECT COUNT(*) FROM $payments_table WHERE status = 'unmatched'");
        $active_devices = $wpdb->get_var("SELECT COUNT(*) FROM $devices_table WHERE status = 'active'");

        $api_url = home_url('/netfie-pay/json/api');

        echo '<div class="wrap">';
        echo '<h1>Pay Checker - Dashboard</h1>';

        echo '<div style="background:#0b63f6; color:#ffffff; padding:20px; border-radius:12px; margin-bottom:20px;">';
        echo '<h2 style="color:#ffffff; margin-top:0;">API Connection Endpoint</h2>';
        echo '<p style="font-size:16px;">Connect your Android Pay Checker App using this URL:</p>';
        echo '<input type="text" value="' . esc_attr($api_url) . '" readonly style="width:100%; max-width:600px; padding:10px; font-size:14px; border-radius:6px; border:none; background:#ffffff; color:#0f172a; font-weight:bold;" onclick="this.select();">';
        echo '</div>';

        echo '<div style="display:flex; gap:15px; margin-bottom:20px;">';
        echo self::stat_box('Total Payments', $total_payments, '#0f172a');
        echo self::stat_box('Verified', $verified_count, '#10b981');
        echo self::stat_box('Unmatched', $unmatched_count, '#ef4444');
        echo self::stat_box('Active Devices', $active_devices, '#0b63f6');
        echo '</div>';

        echo '</div>';
    }

    private static function stat_box($title, $value, $color) {
        return '<div style="flex:1; background:#ffffff; padding:20px; border-radius:10px; border:1px solid #e2e8f0;">' .
               '<div style="font-size:13px; color:#64748b; font-weight:bold;">' . esc_html($title) . '</div>' .
               '<div style="font-size:28px; font-weight:bold; color:' . esc_attr($color) . '; margin-top:5px;">' . esc_html($value) . '</div>' .
               '</div>';
    }

    public static function render_payments_page() {
        global $wpdb;
        $payments_table = $wpdb->prefix . 'pay_checker_payments';
        $rows = $wpdb->get_results("SELECT * FROM $payments_table ORDER BY received_at DESC LIMIT 100");

        echo '<div class="wrap">';
        echo '<h1>Payments History</h1>';
        echo '<table class="wp-list-table widefat fixed striped">';
        echo '<thead><tr><th>Provider</th><th>TrxID</th><th>Amount</th><th>Sender</th><th>Status</th><th>Order ID</th><th>Received At</th></tr></thead>';
        echo '<tbody>';
        if (empty($rows)) {
            echo '<tr><td colspan="7">No payment SMS transactions recorded yet.</td></tr>';
        } else {
            foreach ($rows as $row) {
                $status_color = $row->status === 'verified' ? '#10b981' : '#ef4444';
                $order_link = '-';
                if ($row->order_id) {
                    $order = function_exists('wc_get_order') ? wc_get_order($row->order_id) : false;
                    $order_url = $order ? $order->get_edit_order_url() : admin_url('post.php?post=' . $row->order_id . '&action=edit');
                    $order_link = '<a href="' . esc_url($order_url) . '">#' . intval($row->order_id) . '</a>';
                }
                echo '<tr>';
                echo '<td><strong>' . strtoupper(esc_html($row->provider)) . '</strong></td>';
                echo '<td><code>' . esc_html($row->trx_id) . '</code></td>';
                echo '<td>৳' . esc_html($row->amount) . '</td>';
                echo '<td>' . esc_html($row->sender) . '</td>';
                echo '<td><span style="color:' . $status_color . '; font-weight:bold;">' . esc_html($row->status) . '</span></td>';
                echo '<td>' . $order_link . '</td>';
                echo '<td>' . esc_html($row->received_at) . '</td>';
                echo '</tr>';
            }
        }
        echo '</tbody></table>';
        echo '</div>';
    }

    public static function render_devices_page() {
        global $wpdb;
        $devices_table = $wpdb->prefix . 'pay_checker_devices';
        $rows = $wpdb->get_results("SELECT * FROM $devices_table ORDER BY registered_at DESC");

        echo '<div class="wrap">';
        echo '<h1>Registered Android Devices</h1>';
        echo '<table class="wp-list-table widefat fixed striped">';
        echo '<thead><tr><th>Device ID</th><th>Device Name</th><th>Model</th><th>OS</th><th>Status</th><th>Last Sync</th></tr></thead>';
        echo '<tbody>';
        if (empty($rows)) {
            echo '<tr><td colspan="6">No devices connected yet.</td></tr>';
        } else {
            foreach ($rows as $row) {
                echo '<tr>';
                echo '<td><code>' . esc_html($row->device_id) . '</code></td>';
                echo '<td>' . esc_html($row->device_name) . '</td>';
                echo '<td>' . esc_html($row->device_model) . '</td>';
                echo '<td>' . esc_html($row->os_version) . '</td>';
                echo '<td><span style="color:#10b981; font-weight:bold;">' . esc_html($row->status) . '</span></td>';
                echo '<td>' . esc_html($row->last_sync) . '</td>';
                echo '</tr>';
            }
        }
        echo '</tbody></table>';
        echo '</div>';
    }

    public static function render_settings_page() {
        $settings = get_option('pay_checker_settings', array());

        if (isset($_POST['pay_checker_save_settings'])) {
            check_admin_referer('pay_checker_settings_nonce');
            $settings['auto_order_status'] = sanitize_text_field($_POST['auto_order_status']);

            $settings['bkash_enabled'] = isset($_POST['bkash_enabled']) ? 'yes' : 'no';
            $settings['bkash_number']  = sanitize_text_field($_POST['bkash_number']);

            $settings['nagad_enabled'] = isset($_POST['nagad_enabled']) ? 'yes' : 'no';
            $settings['nagad_number']  = sanitize_text_field($_POST['nagad_number']);

            $settings['rocket_enabled'] = isset($_POST['rocket_enabled']) ? 'yes' : 'no';
            $settings['rocket_number']  = sanitize_text_field($_POST['rocket_number']);

            $settings['upay_enabled'] = isset($_POST['upay_enabled']) ? 'yes' : 'no';
            $settings['upay_number']  = sanitize_text_field($_POST['upay_number']);

            update_option('pay_checker_settings', $settings);
            echo '<div class="updated"><p>Settings saved successfully.</p></div>';
        }

        $auto_status = isset($settings['auto_order_status']) ? $settings['auto_order_status'] : 'processing';

        $bkash_e = !isset($settings['bkash_enabled']) || $settings['bkash_enabled'] === 'yes';
        $bkash   = isset($settings['bkash_number']) ? $settings['bkash_number'] : '';

        $nagad_e = !isset($settings['nagad_enabled']) || $settings['nagad_enabled'] === 'yes';
        $nagad   = isset($settings['nagad_number']) ? $settings['nagad_number'] : '';

        $rocket_e = !isset($settings['rocket_enabled']) || $settings['rocket_enabled'] === 'yes';
        $rocket   = isset($settings['rocket_number']) ? $settings['rocket_number'] : '';

        $upay_e = !isset($settings['upay_enabled']) || $settings['upay_enabled'] === 'yes';
        $upay   = isset($settings['upay_number']) ? $settings['upay_number'] : '';

        echo '<div class="wrap">';
        echo '<h1>Pay Checker Settings</h1>';
        echo '<form method="post" action="">';
        wp_nonce_field('pay_checker_settings_nonce');

        echo '<h2>General Verification Settings</h2>';
        echo '<table class="form-table">';
        echo '<tr><th><label>Auto Update Order Status To</label></th><td>';
        echo '<select name="auto_order_status">';
        echo '<option value="processing" ' . selected($auto_status, 'processing', false) . '>Processing</option>';
        echo '<option value="completed" ' . selected($auto_status, 'completed', false) . '>Completed</option>';
        echo '</select>';
        echo '</td></tr>';
        echo '</table>';

        echo '<h2>Payment Methods & Merchant Wallet Numbers</h2>';
        echo '<table class="form-table">';

        // bKash
        echo '<tr><th><label>bKash Payment</label></th><td>';
        echo '<label style="margin-right:15px;"><input type="checkbox" name="bkash_enabled" value="yes" ' . checked($bkash_e, true, false) . '> Enable bKash</label>';
        echo '<input type="text" name="bkash_number" value="' . esc_attr($bkash) . '" class="regular-text" placeholder="bKash Number">';
        echo '</td></tr>';

        // Nagad
        echo '<tr><th><label>Nagad Payment</label></th><td>';
        echo '<label style="margin-right:15px;"><input type="checkbox" name="nagad_enabled" value="yes" ' . checked($nagad_e, true, false) . '> Enable Nagad</label>';
        echo '<input type="text" name="nagad_number" value="' . esc_attr($nagad) . '" class="regular-text" placeholder="Nagad Number">';
        echo '</td></tr>';

        // Rocket
        echo '<tr><th><label>Rocket Payment</label></th><td>';
        echo '<label style="margin-right:15px;"><input type="checkbox" name="rocket_enabled" value="yes" ' . checked($rocket_e, true, false) . '> Enable Rocket</label>';
        echo '<input type="text" name="rocket_number" value="' . esc_attr($rocket) . '" class="regular-text" placeholder="Rocket Number">';
        echo '</td></tr>';

        // Upay
        echo '<tr><th><label>Upay Payment</label></th><td>';
        echo '<label style="margin-right:15px;"><input type="checkbox" name="upay_enabled" value="yes" ' . checked($upay_e, true, false) . '> Enable Upay</label>';
        echo '<input type="text" name="upay_number" value="' . esc_attr($upay) . '" class="regular-text" placeholder="Upay Number">';
        echo '</td></tr>';

        echo '</table>';

        echo '<p class="submit"><input type="submit" name="pay_checker_save_settings" class="button-primary" value="Save Changes"></p>';
        echo '</form>';
        echo '</div>';
    }

    public static function render_logs_page() {
        global $wpdb;
        $logs_table = $wpdb->prefix . 'pay_checker_logs';
        $rows = $wpdb->get_results("SELECT * FROM $logs_table ORDER BY created_at DESC LIMIT 100");

        echo '<div class="wrap">';
        echo '<h1>System & API Logs</h1>';
        echo '<table class="wp-list-table widefat fixed striped">';
        echo '<thead><tr><th>Type</th><th>Title</th><th>Message</th><th>Timestamp</th></tr></thead>';
        echo '<tbody>';
        if (empty($rows)) {
            echo '<tr><td colspan="4">No logs recorded yet.</td></tr>';
        } else {
            foreach ($rows as $row) {
                echo '<tr>';
                echo '<td><code>' . esc_html($row->type) . '</code></td>';
                echo '<td><strong>' . esc_html($row->title) . '</strong></td>';
                echo '<td>' . esc_html($row->message) . '</td>';
                echo '<td>' . esc_html($row->created_at) . '</td>';
                echo '</tr>';
            }
        }
        echo '</tbody></table>';
        echo '</div>';
    }
}
