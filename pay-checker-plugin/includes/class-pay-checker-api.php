<?php
if (!defined('ABSPATH')) {
    exit;
}

class Pay_Checker_API {

    public static function init() {
        add_action('rest_api_init', array(__CLASS__, 'register_rest_routes'));
    }

    public static function register_rest_routes() {
        register_rest_route('netfie-pay/v1', '/api', array(
            'methods' => array('GET', 'POST', 'OPTIONS'),
            'callback' => array(__CLASS__, 'handle_rest_request'),
            'permission_callback' => '__return_true',
        ));
    }

    public static function handle_rest_request($request) {
        self::process_request();
        exit;
    }

    private static function get_header($name) {
        $key = 'HTTP_' . strtoupper(str_replace('-', '_', $name));
        if (isset($_SERVER[$key]) && !empty($_SERVER[$key])) {
            return sanitize_text_field($_SERVER[$key]);
        }
        if (function_exists('getallheaders')) {
            $headers = getallheaders();
            if (is_array($headers)) {
                foreach ($headers as $k => $v) {
                    if (strtolower($k) === strtolower($name)) {
                        return sanitize_text_field($v);
                    }
                }
            }
        }
        return '';
    }

    public static function process_request() {
        header('Content-Type: application/json; charset=UTF-8');
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, X-Device-ID, X-Device-Token, X-Action');

        if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            status_header(200);
            exit;
        }

        $raw_input = file_get_contents('php://input');
        $json_data = array();
        if (!empty($raw_input)) {
            $decoded = json_decode($raw_input, true);
            if (is_array($decoded)) {
                $json_data = $decoded;
            }
        }

        // Merge input data: JSON body takes precedence, falling back to $_POST, $_GET, $_REQUEST
        $data = array_merge($_GET, $_POST, $_REQUEST, $json_data);

        // Extract action from multiple possible locations
        $action = '';
        if (!empty($data['action'])) {
            $action = sanitize_text_field($data['action']);
        } elseif (!empty($_GET['action'])) {
            $action = sanitize_text_field($_GET['action']);
        } elseif (!empty($_POST['action'])) {
            $action = sanitize_text_field($_POST['action']);
        } elseif (!empty($_REQUEST['action'])) {
            $action = sanitize_text_field($_REQUEST['action']);
        } else {
            $header_action = self::get_header('X-Action');
            if (!empty($header_action)) {
                $action = $header_action;
            }
        }

        // If action is still empty, default to 'connect' for GET requests or empty input
        if (empty($action) && (empty($_SERVER['REQUEST_METHOD']) || $_SERVER['REQUEST_METHOD'] === 'GET' || empty($raw_input))) {
            $action = 'connect';
        }

        // Extract device credentials
        $device_id = self::get_header('X-Device-ID');
        if (empty($device_id) && !empty($data['device_id'])) {
            $device_id = sanitize_text_field($data['device_id']);
        }

        $device_token = self::get_header('X-Device-Token');
        if (empty($device_token) && !empty($data['device_token'])) {
            $device_token = sanitize_text_field($data['device_token']);
        }

        switch ($action) {
            case 'connect':
                self::action_connect();
                break;

            case 'register_device':
                self::action_register_device($data, $device_id);
                break;

            case 'heartbeat':
                self::authenticate_device($device_id, $device_token);
                self::action_heartbeat($device_id);
                break;

            case 'sms_transaction':
                self::authenticate_device($device_id, $device_token);
                self::action_sms_transaction($data, $device_id);
                break;

            case 'sync':
                self::authenticate_device($device_id, $device_token);
                self::action_sync($device_id);
                break;

            case 'get_pending':
                self::authenticate_device($device_id, $device_token);
                self::action_get_pending();
                break;

            case 'get_payment':
                self::authenticate_device($device_id, $device_token);
                self::action_get_payment($data);
                break;

            case 'verify_payment':
                self::authenticate_device($device_id, $device_token);
                self::action_verify_payment($data, $device_id);
                break;

            case 'device_status':
                self::authenticate_device($device_id, $device_token);
                self::action_device_status($device_id);
                break;

            case 'disconnect':
                self::authenticate_device($device_id, $device_token);
                self::action_disconnect($device_id);
                break;

            default:
                self::response_json(false, 'Invalid API action: ' . $action, null, 400);
                break;
        }
    }

    private static function action_connect() {
        $settings = get_option('pay_checker_settings', array());
        $response_data = array(
            'site_name' => get_bloginfo('name'),
            'domain' => parse_url(home_url(), PHP_URL_HOST),
            'plugin_version' => PAY_CHECKER_VERSION,
            'api_version' => '1.0.0',
            'supported_providers' => array('bkash', 'nagad', 'rocket', 'upay'),
        );

        self::response_json(true, 'Pay Checker API endpoint active and ready.', $response_data);
    }

    private static function action_register_device($data, $header_device_id) {
        global $wpdb;

        $device_id = !empty($data['device_id']) ? sanitize_text_field($data['device_id']) : $header_device_id;
        $device_name = !empty($data['device_name']) ? sanitize_text_field($data['device_name']) : 'Android-Device';
        $device_model = !empty($data['device_model']) ? sanitize_text_field($data['device_model']) : 'Android';
        $os_version = !empty($data['os_version']) ? sanitize_text_field($data['os_version']) : 'Android';

        if (empty($device_id)) {
            self::response_json(false, 'Device ID is required for registration.', null, 400);
        }

        $devices_table = $wpdb->prefix . 'pay_checker_devices';
        $device_token = 'nf_dev_' . wp_generate_password(32, false);
        $now = current_time('mysql');

        $existing = $wpdb->get_row($wpdb->prepare("SELECT * FROM $devices_table WHERE device_id = %s", $device_id));

        if ($existing) {
            $wpdb->update(
                $devices_table,
                array(
                    'device_name' => $device_name,
                    'device_model' => $device_model,
                    'os_version' => $os_version,
                    'device_token' => $device_token,
                    'status' => 'active',
                    'last_sync' => $now,
                ),
                array('device_id' => $device_id)
            );
        } else {
            $wpdb->insert(
                $devices_table,
                array(
                    'device_id' => $device_id,
                    'device_name' => $device_name,
                    'device_model' => $device_model,
                    'os_version' => $os_version,
                    'device_token' => $device_token,
                    'status' => 'active',
                    'registered_at' => $now,
                    'last_sync' => $now,
                )
            );
        }

        Pay_Checker_Logger::info('Device Registered', "Device ID: $device_id, Name: $device_name");

        self::response_json(true, 'Device registered successfully.', array(
            'device_id' => $device_id,
            'device_token' => $device_token,
            'status' => 'active',
        ));
    }

    private static function action_heartbeat($device_id) {
        global $wpdb;
        $devices_table = $wpdb->prefix . 'pay_checker_devices';
        $now = current_time('mysql');

        $wpdb->update($devices_table, array('last_sync' => $now), array('device_id' => $device_id));

        self::response_json(true, 'Heartbeat acknowledged', array('timestamp' => $now));
    }

    private static function action_sms_transaction($data, $device_id) {
        $provider = isset($data['provider']) ? sanitize_text_field($data['provider']) : '';
        $trx_id = isset($data['trx_id']) ? sanitize_text_field($data['trx_id']) : '';
        $amount = isset($data['amount']) ? floatval($data['amount']) : 0.0;
        $sender = isset($data['sender']) ? sanitize_text_field($data['sender']) : '';
        $raw_sms = isset($data['raw_sms']) ? sanitize_text_field($data['raw_sms']) : '';

        if (empty($provider) || empty($trx_id) || $amount <= 0) {
            self::response_json(false, 'Missing or invalid parameters (provider, trx_id, amount required).', null, 400);
        }

        $result = Pay_Checker_Matching_Engine::process_sms_transaction(
            $provider,
            $trx_id,
            $amount,
            $sender,
            $raw_sms,
            $device_id
        );

        if ($result['status'] === 'verified') {
            self::response_json(true, 'Payment verified and order status updated.', $result);
        } elseif ($result['status'] === 'duplicate') {
            self::response_json(false, 'Duplicate transaction detected.', $result);
        } else {
            self::response_json(true, 'Transaction recorded as unmatched.', $result);
        }
    }

    private static function action_sync($device_id) {
        global $wpdb;
        $payments_table = $wpdb->prefix . 'pay_checker_payments';

        $rows = $wpdb->get_results("SELECT * FROM $payments_table ORDER BY received_at DESC LIMIT 50", ARRAY_A);

        self::response_json(true, 'Sync completed', array('payments' => $rows));
    }

    private static function action_get_pending() {
        $args = array(
            'status' => array('pending', 'on-hold'),
            'limit' => 20,
        );
        $orders = wc_get_orders($args);

        $list = array();
        foreach ($orders as $order) {
            $list[] = array(
                'order_id' => $order->get_id(),
                'total' => $order->get_total(),
                'customer_name' => $order->get_formatted_billing_full_name(),
                'trx_id' => $order->get_meta('_pay_checker_trx_id'),
                'sender' => $order->get_meta('_pay_checker_sender'),
                'provider' => $order->get_meta('_pay_checker_provider'),
                'created_at' => $order->get_date_created() ? $order->get_date_created()->date('Y-m-d H:i:s') : '',
            );
        }

        self::response_json(true, 'Pending orders retrieved', array('orders' => $list));
    }

    private static function action_get_payment($data) {
        global $wpdb;
        $trx_id = isset($data['trx_id']) ? sanitize_text_field($data['trx_id']) : '';
        $id = isset($data['id']) ? intval($data['id']) : 0;

        $payments_table = $wpdb->prefix . 'pay_checker_payments';

        if (!empty($trx_id)) {
            $row = $wpdb->get_row($wpdb->prepare("SELECT * FROM $payments_table WHERE trx_id = %s", $trx_id), ARRAY_A);
        } else if ($id > 0) {
            $row = $wpdb->get_row($wpdb->prepare("SELECT * FROM $payments_table WHERE id = %d", $id), ARRAY_A);
        } else {
            self::response_json(false, 'trx_id or id parameter required.', null, 400);
        }

        if ($row) {
            self::response_json(true, 'Payment transaction retrieved', $row);
        } else {
            self::response_json(false, 'Payment transaction not found', null, 404);
        }
    }

    private static function action_verify_payment($data, $device_id) {
        $provider = isset($data['provider']) ? sanitize_text_field($data['provider']) : '';
        $trx_id = isset($data['trx_id']) ? sanitize_text_field($data['trx_id']) : '';
        $amount = isset($data['amount']) ? floatval($data['amount']) : 0.0;
        $sender = isset($data['sender']) ? sanitize_text_field($data['sender']) : '';

        $result = Pay_Checker_Matching_Engine::process_sms_transaction(
            $provider,
            $trx_id,
            $amount,
            $sender,
            'Manual verification request from device',
            $device_id
        );

        self::response_json(true, 'Manual payment verification executed', $result);
    }

    private static function action_device_status($device_id) {
        global $wpdb;
        $devices_table = $wpdb->prefix . 'pay_checker_devices';

        $device = $wpdb->get_row($wpdb->prepare("SELECT * FROM $devices_table WHERE device_id = %s", $device_id), ARRAY_A);

        if ($device) {
            self::response_json(true, 'Device status retrieved', $device);
        } else {
            self::response_json(false, 'Device not found', null, 404);
        }
    }

    private static function action_disconnect($device_id) {
        global $wpdb;
        $devices_table = $wpdb->prefix . 'pay_checker_devices';

        $wpdb->update($devices_table, array('status' => 'revoked'), array('device_id' => $device_id));

        self::response_json(true, 'Device revoked successfully', null);
    }

    private static function authenticate_device($device_id, $device_token) {
        global $wpdb;

        if (empty($device_id) || empty($device_token)) {
            self::response_json(false, 'Authentication failure: Missing device ID or Token headers.', null, 401);
        }

        $devices_table = $wpdb->prefix . 'pay_checker_devices';
        $device = $wpdb->get_row($wpdb->prepare(
            "SELECT * FROM $devices_table WHERE device_id = %s AND device_token = %s AND status = 'active'",
            $device_id,
            $device_token
        ));

        if (!$device) {
            self::response_json(false, 'Authentication failure: Invalid or revoked device token.', null, 401);
        }
    }

    private static function response_json($success, $message, $data = null, $http_code = 200) {
        status_header($http_code);
        echo json_encode(array(
            'status' => $success ? 'success' : 'error',
            'success' => $success,
            'message' => $message,
            'data' => $data,
        ));
        exit;
    }
}
