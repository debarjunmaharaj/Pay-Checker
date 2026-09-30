<?php
/**
 * Plugin Name: Pay Checker - Automated Payment Verification
 * Plugin URI: https://netfie.com/pay-checker
 * Description: Production-ready automatic payment verification system for bKash, Nagad, Rocket, Upay and other Bangladeshi MFS providers. Automatically verifies TrxID and marks WooCommerce orders as paid.
 * Version: 1.0.0
 * Author: Netfie Development Team
 * Author URI: https://netfie.com
 * Text Domain: pay-checker
 * Domain Path: /languages
 * WC requires at least: 5.0.0
 * WC tested up to: 8.9.0
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly
}

define('PAY_CHECKER_VERSION', '1.0.0');
define('PAY_CHECKER_FILE', __FILE__);
define('PAY_CHECKER_PATH', plugin_dir_path(__FILE__));
define('PAY_CHECKER_URL', plugin_dir_url(__FILE__));
define('PAY_CHECKER_API_ENDPOINT', 'netfie-pay/json/api');

require_once PAY_CHECKER_PATH . 'includes/class-pay-checker-db.php';
require_once PAY_CHECKER_PATH . 'includes/class-pay-checker-logger.php';
require_once PAY_CHECKER_PATH . 'includes/class-pay-checker-api.php';
require_once PAY_CHECKER_PATH . 'includes/class-pay-checker-matching-engine.php';
require_once PAY_CHECKER_PATH . 'includes/class-pay-checker-admin.php';

// Declare WooCommerce Compatibility (HPOS & Blocks)
add_action('before_woocommerce_init', function() {
    if (class_exists('\Automattic\WooCommerce\Utilities\FeaturesUtil')) {
        \Automattic\WooCommerce\Utilities\FeaturesUtil::declare_compatibility('custom_order_tables', __FILE__, true);
        \Automattic\WooCommerce\Utilities\FeaturesUtil::declare_compatibility('cart_checkout_blocks', __FILE__, true);
    }
});

class Pay_Checker {

    private static $instance = null;

    public static function get_instance() {
        if (null === self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    private function __construct() {
        register_activation_hook(PAY_CHECKER_FILE, array($this, 'activate'));
        register_deactivation_hook(PAY_CHECKER_FILE, array($this, 'deactivate'));

        add_action('plugins_loaded', array($this, 'init'));
        add_action('init', array($this, 'add_rewrite_rules'));
        add_action('init', array($this, 'check_early_api_request'), 5);
        add_filter('query_vars', array($this, 'add_query_vars'));
        add_action('template_redirect', array($this, 'handle_custom_api_endpoint'));
        add_action('wp_enqueue_scripts', array($this, 'enqueue_scripts'));

        // Register WooCommerce Gateway
        add_filter('woocommerce_payment_gateways', array($this, 'register_gateway'));
    }

    public function activate() {
        Pay_Checker_DB::create_tables();
        $this->add_rewrite_rules();
        flush_rewrite_rules();

        if (!get_option('pay_checker_settings')) {
            update_option('pay_checker_settings', array(
                'auto_order_status' => 'processing',
                'match_time_window' => 24,
                'bkash_enabled' => 'yes',
                'bkash_number' => '01700000000',
                'nagad_enabled' => 'yes',
                'nagad_number' => '01800000000',
                'rocket_enabled' => 'yes',
                'rocket_number' => '01900000000',
                'upay_enabled' => 'yes',
                'upay_number' => '01600000000',
            ));
        }

        Pay_Checker_Logger::info('Pay Checker plugin activated successfully.');
    }

    public function deactivate() {
        flush_rewrite_rules();
        Pay_Checker_Logger::info('Pay Checker plugin deactivated.');
    }

    public function init() {
        Pay_Checker_API::init();
        if (is_admin()) {
            Pay_Checker_Admin::init();
        }
    }

    public function enqueue_scripts() {
        if (function_exists('is_checkout') && (is_checkout() || is_order_received_page())) {
            wp_enqueue_style('pay-checker-google-fonts', 'https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=Space+Mono:wght@400;700&display=swap', array(), null);
            wp_enqueue_style('pay-checker-checkout-css', PAY_CHECKER_URL . 'assets/css/checkout.css', array(), PAY_CHECKER_VERSION);
            wp_enqueue_script('pay-checker-checkout-js', PAY_CHECKER_URL . 'assets/js/checkout.js', array('jquery'), PAY_CHECKER_VERSION, true);
        }
    }

    public function add_rewrite_rules() {
        add_rewrite_rule('^netfie-pay/json/api/?$', 'index.php?pay_checker_api=1', 'top');
    }

    public function add_query_vars($vars) {
        $vars[] = 'pay_checker_api';
        return $vars;
    }

    public function check_early_api_request() {
        $request_uri = isset($_SERVER['REQUEST_URI']) ? $_SERVER['REQUEST_URI'] : '';
        if (strpos($request_uri, 'netfie-pay/json/api') !== false) {
            Pay_Checker_API::process_request();
            exit;
        }
    }

    public function handle_custom_api_endpoint() {
        global $wp_query;
        $request_uri = isset($_SERVER['REQUEST_URI']) ? $_SERVER['REQUEST_URI'] : '';
        if (isset($wp_query->query_vars['pay_checker_api']) ||
            strpos($request_uri, 'netfie-pay/json/api') !== false) {
            Pay_Checker_API::process_request();
            exit;
        }
    }

    public function register_gateway($gateways) {
        require_once PAY_CHECKER_PATH . 'includes/class-pay-checker-gateway.php';
        $gateways[] = 'WC_Gateway_Pay_Checker';
        return $gateways;
    }
}

Pay_Checker::get_instance();
