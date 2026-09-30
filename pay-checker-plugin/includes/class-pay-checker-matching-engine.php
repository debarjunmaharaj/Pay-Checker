<?php
if (!defined('ABSPATH')) {
    exit;
}

class Pay_Checker_Matching_Engine {

    public static function process_sms_transaction($provider, $trx_id, $amount, $sender, $raw_sms, $device_id = '') {
        global $wpdb;

        $provider = strtolower(trim($provider));
        $trx_id = strtoupper(trim($trx_id));
        $amount = floatval($amount);
        $sender = trim($sender);

        $payments_table = $wpdb->prefix . 'pay_checker_payments';

        // 1. Check for Duplicate TrxID
        $existing = $wpdb->get_row($wpdb->prepare(
            "SELECT * FROM $payments_table WHERE provider = %s AND trx_id = %s",
            $provider,
            $trx_id
        ));

        if ($existing) {
            Pay_Checker_Logger::warning('Duplicate TrxID Received', "Provider: $provider, TrxID: $trx_id");
            return array(
                'status' => 'duplicate',
                'id' => $existing->id,
                'trx_id' => $existing->trx_id,
                'provider' => $existing->provider,
                'amount' => $existing->amount,
                'sender' => $existing->sender,
                'status_label' => 'duplicate',
                'message' => 'Duplicate TrxID. Payment already processed previously.',
            );
        }

        // 2. Search for Matching Pending WooCommerce Order
        $matched_order_id = self::find_matching_order($provider, $trx_id, $amount, $sender);

        $status = $matched_order_id ? 'verified' : 'unmatched';
        $now = current_time('mysql');

        // 3. Save into Database
        $wpdb->insert(
            $payments_table,
            array(
                'trx_id' => $trx_id,
                'provider' => $provider,
                'amount' => $amount,
                'sender' => $sender,
                'raw_sms' => $raw_sms,
                'status' => $status,
                'order_id' => $matched_order_id ? $matched_order_id : null,
                'device_id' => $device_id,
                'received_at' => $now,
                'processed_at' => $now,
            )
        );

        $insert_id = $wpdb->insert_id;

        // 4. Update WooCommerce Order if Matched
        if ($matched_order_id) {
            $order = wc_get_order($matched_order_id);
            if ($order) {
                $settings = get_option('pay_checker_settings', array());
                $target_status = isset($settings['auto_order_status']) && $settings['auto_order_status'] === 'completed'
                    ? 'completed'
                    : 'processing';

                $order->update_status(
                    $target_status,
                    sprintf(
                        __('[Pay Checker] Payment verified automatically via %s SMS. TrxID: %s, Amount: ৳%s, Sender: %s.', 'pay-checker'),
                        strtoupper($provider),
                        $trx_id,
                        $amount,
                        $sender
                    )
                );

                $order->update_meta_data('_pay_checker_verified', 'yes');
                $order->update_meta_data('_pay_checker_verified_at', $now);
                $order->update_meta_data('_pay_checker_trx_id', $trx_id);
                $order->update_meta_data('_pay_checker_provider', $provider);
                $order->save();

                Pay_Checker_Logger::verification(
                    'Order Verified',
                    "Order #$matched_order_id marked as $target_status via $provider SMS (TrxID: $trx_id, ৳$amount)"
                );
            }
        } else {
            Pay_Checker_Logger::info(
                'Unmatched Payment',
                "Received $provider SMS (TrxID: $trx_id, ৳$amount). No pending matching order found."
            );
        }

        return array(
            'id' => $insert_id,
            'trx_id' => $trx_id,
            'provider' => $provider,
            'amount' => $amount,
            'sender' => $sender,
            'raw_sms' => $raw_sms,
            'status' => $status,
            'order_id' => $matched_order_id ? (string)$matched_order_id : null,
            'received_at' => $now,
            'processed_at' => $now,
            'is_synced' => 1,
        );
    }

    private static function find_matching_order($provider, $trx_id, $amount, $sender) {
        $settings = get_option('pay_checker_settings', array());
        $time_window_hours = isset($settings['match_time_window']) ? intval($settings['match_time_window']) : 24;

        $args = array(
            'status' => array('pending', 'on-hold', 'failed'),
            'limit' => 50,
            'orderby' => 'date',
            'order' => 'DESC',
        );

        $orders = wc_get_orders($args);

        foreach ($orders as $order) {
            $order_total = floatval($order->get_total());

            // Check Amount Match (tolerance 0.50)
            if (abs($order_total - $amount) > 0.50) {
                continue;
            }

            $order_trx = strtoupper(trim($order->get_meta('_pay_checker_trx_id')));
            $order_sender = trim($order->get_meta('_pay_checker_sender'));
            $order_provider = strtolower(trim($order->get_meta('_pay_checker_provider')));

            // Match Priority 1: Exact TrxID
            if (!empty($order_trx) && $order_trx === $trx_id) {
                return $order->get_id();
            }

            // Match Priority 2: Amount + Sender Mobile Number
            if (!empty($order_sender) && !empty($sender)) {
                $clean_order_sender = preg_replace('/[^0-9]/', '', $order_sender);
                $clean_sms_sender = preg_replace('/[^0-9]/', '', $sender);

                if (strlen($clean_order_sender) >= 11 && strlen($clean_sms_sender) >= 11) {
                    if (substr($clean_order_sender, -11) === substr($clean_sms_sender, -11)) {
                        return $order->get_id();
                    }
                }
            }
        }

        return false;
    }
}
