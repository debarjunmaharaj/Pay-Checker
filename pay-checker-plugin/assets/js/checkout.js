/**
 * ApexPay / Pay Checker - Modern 2-Column Checkout Layout & Interactions (Clean Single-Instance)
 */
jQuery(document).ready(function($) {

    // 1. Inject Ambient Glow Background Once
    function initAmbientBackground() {
        if (!$('.pay-checker-glow-bg').length && $('form.woocommerce-checkout').length) {
            var bgHtml = `
            <div class="pay-checker-glow-bg" aria-hidden="true">
                <div class="pay-checker-glow-blob pay-checker-glow-1"></div>
                <div class="pay-checker-glow-blob pay-checker-glow-2"></div>
                <div class="pay-checker-glow-blob pay-checker-glow-3"></div>
            </div>`;
            $('body').prepend(bgHtml);
        }
    }

    // 2. Clean 2-Column Layout Setup (No Duplication)
    function organizeCheckoutLayout() {
        var $form = $('form.woocommerce-checkout');
        if (!$form.length) return;

        // Remove any legacy duplicate wrappers if present
        $('#pay_checker_two_col_wrapper').remove();

        // Top Trust Header (Inject once at top of checkout form)
        if (!$('#pay_checker_trust_header').length) {
            var headerHtml = `
            <div id="pay_checker_trust_header" class="pay-checker-top-header">
                <div class="pay-checker-brand-badge">
                    <div class="pay-checker-brand-icon">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                    </div>
                    <div>
                        <span class="pay-checker-brand-title">Secure Checkout</span>
                        <span class="pay-checker-pill">SSL 256-Bit</span>
                    </div>
                </div>
                <div class="pay-checker-security-info">
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#059669" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                    <span>End-to-End Encrypted</span>
                </div>
            </div>`;
            $form.prepend(headerHtml);
        }

        // Left Column: Payment Methods Card (Inject once right after customer billing/shipping details)
        if (!$('#pay_checker_payment_card').length) {
            var paymentCardHtml = `
            <div id="pay_checker_payment_card" class="pay-checker-section-card">
                <div class="pay-checker-section-header">
                    <div class="pay-checker-step-circle">2</div>
                    <div>
                        <h3 class="pay-checker-section-title">Payment Method</h3>
                        <p class="pay-checker-section-desc">Select your preferred payment gateway</p>
                    </div>
                </div>
                <div id="pay_checker_methods_slot"></div>
            </div>`;

            var $target = $('.woocommerce-additional-fields').length ? $('.woocommerce-additional-fields') : $('#customer_details');
            if ($target.length) {
                $target.after(paymentCardHtml);
            } else if ($('#order_review').length) {
                $('#order_review').before(paymentCardHtml);
            }
        }

        // Move Payment Methods list from #payment to Left Column slot
        var $payment = $('#payment');
        if ($payment.length) {
            var $methods = $payment.find('ul.wc_payment_methods');
            if ($methods.length) {
                var $slot = $('#pay_checker_methods_slot');
                if (!$.contains($slot[0], $methods[0])) {
                    $slot.empty().append($methods);
                }
            }
        }

        // Right Column: Enhance existing native #order_review (Order Summary Card)
        var $orderReview = $('#order_review');
        if ($orderReview.length) {
            $orderReview.addClass('pay-checker-order-summary-card');

            // Order summary card header (Inject once at top of #order_review)
            if (!$('#pay_checker_summary_header').length) {
                $orderReview.prepend(`
                    <div id="pay_checker_summary_header" class="pay-checker-card-header">
                        <h3 class="pay-checker-summary-title">Order Summary</h3>
                        <span class="pay-checker-summary-tag">Secure Review</span>
                    </div>
                `);
            }

            // Trust badges (Inject once at bottom of #order_review)
            if (!$('#pay_checker_trust_badges').length) {
                $orderReview.append(`
                    <div id="pay_checker_trust_badges" class="pay-checker-trust-badges">
                        <div class="pay-checker-trust-item">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                            <span>Buyer Protection</span>
                        </div>
                        <div class="pay-checker-trust-item">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/><path d="M16 21h5v-5"/></svg>
                            <span>Instant Verification</span>
                        </div>
                        <div class="pay-checker-trust-item">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg>
                            <span>100% Secure</span>
                        </div>
                    </div>
                `);
            }
        }

        // Update selected state styling on payment methods
        highlightSelectedMethod();

        // Restore saved status pill if TrxID already filled
        updateSavedStatusDisplay();
    }

    // Highlight selected payment radio
    function highlightSelectedMethod() {
        $('ul.wc_payment_methods li.wc_payment_method').removeClass('pc-selected');
        $('ul.wc_payment_methods input[type="radio"]:checked')
            .closest('li.wc_payment_method')
            .addClass('pc-selected');
    }

    $(document).on('change', 'ul.wc_payment_methods input[type="radio"]', function() {
        highlightSelectedMethod();
    });

    // 3. Provider Card Tap & Modal Interaction (bKash, Nagad, Rocket, Upay)
    $(document).on('click', '.pay-checker-provider-card', function(e) {
        e.preventDefault();
        var provider = $(this).data('provider');
        var name = $(this).data('name');
        var icon = $(this).data('icon');
        var number = $(this).data('number') || '01700000000';

        $('.pay-checker-provider-card').removeClass('selected');
        $(this).addClass('selected');

        // Update Hidden Form Field
        $('#pay_checker_provider').val(provider);

        // Update Modal UI
        $('#pay_checker_modal_icon').attr('src', icon);
        $('#pay_checker_modal_title').text(name + ' Payment Details');
        $('#pay_checker_modal_number').text(number);
        $('#pay_checker_modal_provider_label').text(name + ' Personal / Merchant Number');

        // Pre-fill existing modal values
        $('#pay_checker_modal_sender').val($('#pay_checker_sender').val());
        $('#pay_checker_modal_trx').val($('#pay_checker_trx_id').val());

        // Open Modal
        $('#pay_checker_modal_overlay').addClass('active');
        $('#pay_checker_modal_sender').focus();
    });

    // Close Modal
    function closeModal() {
        $('#pay_checker_modal_overlay').removeClass('active');
    }

    $(document).on('click', '#pay_checker_modal_close, #pay_checker_modal_overlay', function(e) {
        if (e.target === this) {
            closeModal();
        }
    });

    $(document).keyup(function(e) {
        if (e.key === "Escape") {
            closeModal();
        }
    });

    // Re-open modal via edit button
    $(document).on('click', '#pay_checker_edit_details_btn', function(e) {
        e.preventDefault();
        var $activeCard = $('.pay-checker-provider-card.selected');
        if ($activeCard.length) {
            $activeCard.trigger('click');
        } else {
            $('.pay-checker-provider-card').first().trigger('click');
        }
    });

    // Copy Merchant Number
    $(document).on('click', '#pay_checker_copy_btn', function(e) {
        e.preventDefault();
        var num = $('#pay_checker_modal_number').text().trim();
        var $btn = $(this);

        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(num).then(function() {
                showCopiedFeedback($btn);
            });
        } else {
            var $temp = $("<input>");
            $("body").append($temp);
            $temp.val(num).select();
            document.execCommand("copy");
            $temp.remove();
            showCopiedFeedback($btn);
        }
    });

    function showCopiedFeedback($btn) {
        var originalText = $btn.text();
        $btn.text('Copied! ✓').addClass('copied');
        setTimeout(function() {
            $btn.text(originalText).removeClass('copied');
        }, 2200);
    }

    // Confirm & Save Details from Modal
    $(document).on('click', '#pay_checker_confirm_btn', function(e) {
        e.preventDefault();

        var sender = $('#pay_checker_modal_sender').val().trim();
        var trx = $('#pay_checker_modal_trx').val().trim().toUpperCase();

        if (!sender) {
            alert('Please enter your sender mobile number.');
            $('#pay_checker_modal_sender').focus();
            return;
        }

        if (!trx) {
            alert('Please enter your Transaction ID (TrxID).');
            $('#pay_checker_modal_trx').focus();
            return;
        }

        // Save into main checkout form inputs
        $('#pay_checker_sender').val(sender);
        $('#pay_checker_trx_id').val(trx);

        updateSavedStatusDisplay();
        closeModal();
    });

    function updateSavedStatusDisplay() {
        var sender = $('#pay_checker_sender').val();
        var trx = $('#pay_checker_trx_id').val();
        var provider = $('#pay_checker_provider').val() || 'bKash';

        if (trx && sender) {
            $('#pay_checker_summary_provider').text(provider.toUpperCase());
            $('#pay_checker_summary_sender').text(sender);
            $('#pay_checker_summary_trx').text(trx);
            $('#pay_checker_selected_status').fadeIn(200);
        } else {
            $('#pay_checker_selected_status').hide();
        }
    }

    // 4. Hook into WooCommerce Lifecycle
    initAmbientBackground();
    organizeCheckoutLayout();

    // Re-run on WooCommerce AJAX Cart / Review updates (single clean pass)
    $(document.body).on('updated_checkout payment_method_selected', function() {
        organizeCheckoutLayout();
    });

});
