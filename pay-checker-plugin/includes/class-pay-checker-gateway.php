<?php
if (!defined('ABSPATH')) {
    exit;
}

class WC_Gateway_Pay_Checker extends WC_Payment_Gateway {

    public function __construct() {
        $this->id = 'pay_checker';
        $this->icon = PAY_CHECKER_URL . 'assets/images/pay-checker-logo.png';
        $this->has_fields = true;
        $this->method_title = __('Pay Now (Pay Checker)', 'pay-checker');
        $this->method_description = __('Automated instant payment verification for bKash, Nagad, Rocket and Upay mobile banking.', 'pay-checker');

        $this->init_form_fields();
        $this->init_settings();

        $saved_title = $this->get_option('title', 'Pay Now');
        if (empty($saved_title) || strpos($saved_title, 'bKash') !== false || strpos($saved_title, 'Instant Verification') !== false) {
            $this->title = __('Pay Now', 'pay-checker');
        } else {
            $this->title = $saved_title;
        }
        $this->description = $this->get_option('description', '');

        add_filter('woocommerce_gateway_title', array($this, 'filter_gateway_title'), 20, 2);
        add_action('woocommerce_update_options_payment_gateways_' . $this->id, array($this, 'process_admin_options'));
        add_action('woocommerce_thankyou_' . $this->id, array($this, 'thankyou_page'));
        add_action('woocommerce_order_details_after_order_table', array($this, 'display_order_payment_info'));
    }

    public function filter_gateway_title($title, $id) {
        if ($id === $this->id) {
            if (empty($title) || strpos($title, 'Instant Verification') !== false || strpos($title, 'bKash') !== false) {
                return __('Pay Now', 'pay-checker');
            }
        }
        return $title;
    }

    public function init_form_fields() {
        $this->form_fields = array(
            'enabled' => array(
                'title'   => __('Enable/Disable', 'pay-checker'),
                'type'    => 'checkbox',
                'label'   => __('Enable Pay Checker Gateway', 'pay-checker'),
                'default' => 'yes',
            ),
            'title' => array(
                'title'       => __('Title', 'pay-checker'),
                'type'        => 'text',
                'description' => __('Payment method title displayed during checkout.', 'pay-checker'),
                'default'     => __('Pay Now', 'pay-checker'),
                'desc_tip'    => true,
            ),
        );
    }

    public function payment_fields() {
        $settings = get_option('pay_checker_settings', array());

        $bkash_e  = !isset($settings['bkash_enabled']) || $settings['bkash_enabled'] === 'yes';
        $bkash    = !empty($settings['bkash_number']) ? $settings['bkash_number'] : '01700000000';

        $nagad_e  = !isset($settings['nagad_enabled']) || $settings['nagad_enabled'] === 'yes';
        $nagad    = !empty($settings['nagad_number']) ? $settings['nagad_number'] : '01800000000';

        $rocket_e = !isset($settings['rocket_enabled']) || $settings['rocket_enabled'] === 'yes';
        $rocket   = !empty($settings['rocket_number']) ? $settings['rocket_number'] : '01900000000';

        $upay_e   = !isset($settings['upay_enabled']) || $settings['upay_enabled'] === 'yes';
        $upay     = !empty($settings['upay_number']) ? $settings['upay_number'] : '01600000000';

        $all_providers = array(
            'bkash' => array(
                'enabled' => $bkash_e,
                'name'    => 'bKash',
                'number'  => $bkash,
                'icon'    => 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSGKVajXbpgiLCgfbvBX55-ekVu9vpzJSPVwlkf1ZJbaw&s=10',
            ),
            'nagad' => array(
                'enabled' => $nagad_e,
                'name'    => 'Nagad',
                'number'  => $nagad,
                'icon'    => 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQlv2wHW4zu1ep4UTwDXkikRHesSiFGJoTuOGvwxoQaQw&s=10',
            ),
            'rocket' => array(
                'enabled' => $rocket_e,
                'name'    => 'Rocket',
                'number'  => $rocket,
                'icon'    => 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTCJU_NQ8Kgp5Tm2Xpve2pE0ultIonRKDyHpYEuqwnKHQ&s=10',
            ),
            'upay' => array(
                'enabled' => $upay_e,
                'name'    => 'Upay',
                'number'  => $upay,
                'icon'    => 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ0iIce7y0m6KThV6u-PPicwfkRjICIlCJcK2azeMMBLQ&s=10',
            ),
        );

        $providers = array();
        foreach ($all_providers as $key => $p) {
            if ($p['enabled']) {
                $providers[$key] = $p;
            }
        }

        if (empty($providers)) {
            echo '<p style="color:#ef4444; font-size:13px;">No mobile payment methods are currently enabled.</p>';
            return;
        }

        $default_provider_key = array_key_first($providers);

        echo '<div class="pay-checker-checkout-container">';
        echo '  <div class="pay-checker-gateway-banner">';
        echo '    <div class="pay-checker-badge-instant">';
        echo '      <span class="pay-checker-pulse-dot"></span>';
        echo '      <span>Instant Verification</span>';
        echo '    </div>';
        echo '    <span class="pay-checker-gateway-hint">Tap your mobile wallet to view account number & enter TrxID</span>';
        echo '  </div>';
        echo '  <div class="pay-checker-provider-grid">';
        foreach ($providers as $key => $p) {
            echo '<div class="pay-checker-provider-card" data-provider="' . esc_attr($key) . '" data-name="' . esc_attr($p['name']) . '" data-icon="' . esc_url($p['icon']) . '" data-number="' . esc_attr($p['number']) . '">';
            echo '  <div class="pay-checker-card-check"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.5"><polyline points="20 6 9 17 4 12"/></svg></div>';
            echo '  <img src="' . esc_url($p['icon']) . '" alt="' . esc_attr($p['name']) . '">';
            echo '  <span class="provider-name">' . esc_html($p['name']) . '</span>';
            echo '  <span class="provider-action">Pay with ' . esc_html($p['name']) . '</span>';
            echo '</div>';
        }
        echo '  </div>';

        // Hidden Inputs for WooCommerce Form Post
        echo '<input type="hidden" name="pay_checker_provider" id="pay_checker_provider" value="' . esc_attr($default_provider_key) . '" />';
        echo '<input type="hidden" name="pay_checker_sender" id="pay_checker_sender" value="" />';
        echo '<input type="hidden" name="pay_checker_trx_id" id="pay_checker_trx_id" value="" />';

        // Selected summary indicator inside checkout
        echo '<div id="pay_checker_selected_status" class="pay-checker-selected-status" style="display:none;">';
        echo '  <div class="pay-checker-status-inner">';
        echo '    <div class="pay-checker-status-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg></div>';
        echo '    <div>';
        echo '      <div class="pay-checker-status-title"><strong id="pay_checker_summary_provider">bKash</strong> details saved</div>';
        echo '      <div class="pay-checker-status-sub">Sender: <span id="pay_checker_summary_sender"></span> &bull; TrxID: <span id="pay_checker_summary_trx"></span></div>';
        echo '    </div>';
        echo '  </div>';
        echo '  <button type="button" class="pay-checker-edit-details-btn" id="pay_checker_edit_details_btn">Edit</button>';
        echo '</div>';

        // Animated Popup Modal HTML
        echo '<div class="pay-checker-modal-overlay" id="pay_checker_modal_overlay">';
        echo '  <div class="pay-checker-modal-content">';
        echo '    <button type="button" class="pay-checker-modal-close" id="pay_checker_modal_close" aria-label="Close">&times;</button>';
        echo '    <div class="pay-checker-modal-header">';
        echo '      <div class="pay-checker-modal-icon-wrap"><img src="" id="pay_checker_modal_icon" alt="Provider Icon"></div>';
        echo '      <h3 id="pay_checker_modal_title">Payment Details</h3>';
        echo '      <p class="pay-checker-modal-sub">Send money to merchant number and submit transaction details below</p>';
        echo '    </div>';
        echo '    <div class="pay-checker-merchant-box">';
        echo '      <div class="pay-checker-merchant-info">';
        echo '        <span class="pay-checker-merchant-label" id="pay_checker_modal_provider_label">Personal / Merchant Number</span>';
        echo '        <span class="pay-checker-merchant-number" id="pay_checker_modal_number">01700000000</span>';
        echo '      </div>';
        echo '      <button type="button" class="pay-checker-copy-btn" id="pay_checker_copy_btn">Copy</button>';
        echo '    </div>';
        echo '    <div class="pay-checker-field-group">';
        echo '      <label for="pay_checker_modal_sender">Your Sender Mobile Number <span style="color:#ef4444">*</span></label>';
        echo '      <input type="text" id="pay_checker_modal_sender" placeholder="e.g. 01712345678" required autocomplete="tel">';
        echo '    </div>';
        echo '    <div class="pay-checker-field-group">';
        echo '      <label for="pay_checker_modal_trx">Transaction ID (TrxID) <span style="color:#ef4444">*</span></label>';
        echo '      <input type="text" id="pay_checker_modal_trx" placeholder="e.g. 8ABCD12345" required autocomplete="off" style="text-transform:uppercase;">';
        echo '    </div>';
        echo '    <button type="button" class="pay-checker-confirm-btn" id="pay_checker_confirm_btn">Confirm & Save Details</button>';
        echo '  </div>';
        echo '</div>';

        echo '</div>';
    }

    public function validate_fields() {
        if (empty($_POST['pay_checker_provider'])) {
            wc_add_notice(__('Please select a payment provider (bKash/Nagad/Rocket/Upay).', 'pay-checker'), 'error');
            return false;
        }
        if (empty($_POST['pay_checker_sender'])) {
            wc_add_notice(__('Please click your payment method and enter your sender mobile number.', 'pay-checker'), 'error');
            return false;
        }
        if (empty($_POST['pay_checker_trx_id'])) {
            wc_add_notice(__('Please click your payment method and enter the Transaction ID (TrxID).', 'pay-checker'), 'error');
            return false;
        }
        return true;
    }

    public function process_payment($order_id) {
        $order = wc_get_order($order_id);

        $provider = isset($_POST['pay_checker_provider']) ? sanitize_text_field($_POST['pay_checker_provider']) : '';
        $sender   = isset($_POST['pay_checker_sender']) ? sanitize_text_field($_POST['pay_checker_sender']) : '';
        $trx_id   = isset($_POST['pay_checker_trx_id']) ? strtoupper(sanitize_text_field($_POST['pay_checker_trx_id'])) : '';

        $order->update_meta_data('_pay_checker_provider', $provider);
        $order->update_meta_data('_pay_checker_sender', $sender);
        $order->update_meta_data('_pay_checker_trx_id', $trx_id);
        $order->save();

        $order->update_status('on-hold', sprintf(
            __('[Pay Checker] Awaiting payment verification for %s. TrxID: %s, Sender: %s.', 'pay-checker'),
            strtoupper($provider),
            $trx_id,
            $sender
        ));

        WC()->cart->empty_cart();

        return array(
            'result'   => 'success',
            'redirect' => $this->get_return_url($order),
        );
    }

    public function thankyou_page($order_id) {
        $this->display_order_payment_info(wc_get_order($order_id));
    }

    public function display_order_payment_info($order) {
        if (!$order) return;

        $provider = $order->get_meta('_pay_checker_provider');
        $sender   = $order->get_meta('_pay_checker_sender');
        $trx_id   = $order->get_meta('_pay_checker_trx_id');
        $verified = $order->get_meta('_pay_checker_verified');
        $verified_at = $order->get_meta('_pay_checker_verified_at');

        if (empty($trx_id) && empty($provider)) {
            return;
        }

        $is_verified = ($verified === 'yes' || $order->is_paid());
        $status_label = $is_verified ? 'Verified & Paid' : 'Verification Pending';
        $status_color = $is_verified ? '#10b981' : '#f59e0b';
        $bg_color     = $is_verified ? '#ecfdf5' : '#fffbe2';

        echo '<div class="pay-checker-order-payment-details" style="margin-top:20px; padding:20px; background:' . $bg_color . '; border:1px solid ' . $status_color . '; border-radius:12px;">';
        echo '<h3 style="margin-top:0; margin-bottom:12px; font-size:18px; color:#0f172a; font-weight:700;">💳 Pay Checker Payment Details</h3>';

        echo '<div style="display:grid; grid-template-columns: repeat(2, 1fr); gap:12px; font-size:14px;">';
        echo '<div><strong>Payment Provider:</strong> ' . esc_html(strtoupper($provider)) . '</div>';
        echo '<div><strong>Sender Number:</strong> ' . esc_html($sender) . '</div>';
        echo '<div><strong>Transaction ID (TrxID):</strong> <code style="font-weight:bold; background:#ffffff; padding:2px 6px; border-radius:4px;">' . esc_html($trx_id) . '</code></div>';
        echo '<div><strong>Status:</strong> <span style="color:' . $status_color . '; font-weight:bold;">' . esc_html($status_label) . '</span></div>';
        if ($verified_at) {
            echo '<div style="grid-column: span 2;"><strong>Verified At:</strong> ' . esc_html($verified_at) . '</div>';
        }
        echo '</div>';

        echo '</div>';
    }
}
