<div align="center">
  <img src="assets/icon.png" width="120" height="120" alt="Pay Checker Logo" />
  <h1>Pay Checker</h1>
  <p><strong>Automatic Mobile Financial Services (MFS) Payment Verification System</strong></p>
  <p>Real-time SMS detection & automatic order verification for bKash, Nagad, Rocket, and Upay in Bangladesh.</p>

  <a href="https://netfie.com"><img src="https://img.shields.io/badge/Developed%20By-Netfie-blue.svg" alt="Developed by Netfie" /></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20WooCommerce%20%7C%20Laravel%20%7C%20PHP-green.svg" alt="Platforms" />
  <img src="https://img.shields.io/badge/Version-1.0.0-brightgreen.svg" alt="Version 1.0.0" />
</div>

---

## 📌 Overview

**Pay Checker** is an automated payment verification solution designed for modern e-commerce websites and merchants in Bangladesh. It connects an Android phone running payment apps (bKash, Nagad, Rocket, Upay) directly with online stores or custom web applications.

When a customer pays via MFS, the Android app reads the incoming payment SMS, parses the **Transaction ID (TrxID)**, **Amount**, and **Sender Number**, and sends it to the server in real-time. The server then automatically matches the transaction with pending orders and updates the order status instantly.

---

## ✨ Key Features

- ⚡ **Real-Time SMS Detection**: Automatic background SMS parsing for bKash, Nagad, Rocket, and Upay.
- 🔒 **Soft Permission Strategy**: 100% compliant with Google Play Protect policy. No intrusive permission popups on first launch.
- 📱 **Multi-Device Support**: Connect multiple merchant phones to a single website.
- 🛒 **WooCommerce Plugin Included**: Ready-to-use WordPress plugin with automatic REST API generation.
- 💻 **Universal REST API**: Easy integration with **Laravel**, **Custom PHP**, **Node.js**, **Python**, or any framework.
- 🔋 **Battery Optimization Guidance**: In-app guide for OEM devices (Xiaomi, Vivo, Oppo, Samsung) to ensure non-stop background execution.
- 🛡️ **Security First**: Device token authentication, HTTPS enforcement, and duplicate TrxID prevention.

---

## 💳 Supported Payment Providers

| Provider | Method Type | Auto Parsing | Status |
| :--- | :--- | :---: | :---: |
| **bKash** | Personal / Agent / Merchant | ✅ | Supported |
| **Nagad** | Personal / Merchant | ✅ | Supported |
| **Rocket** | Personal / Merchant | ✅ | Supported |
| **Upay** | Personal / Merchant | ✅ | Supported |

---

## 👨‍💻 Developer & Company Information

Pay Checker is developed and maintained by **Netfie**.

- **Company Name**: Netfie
- **Website**: [https://netfie.com](https://netfie.com)
- **WhatsApp Support**: `+8801884189495` ([Chat on WhatsApp](https://wa.me/8801884189495))
- **Mobile Hotline**: `+8801772326146`

---

## 📱 Android App Setup

### 1. Installation
1. Install the Pay Checker APK on the merchant's Android phone (the phone receiving MFS payment SMS).
2. Launch the application. You will see the clean onboarding screen.

### 2. Website Connection
1. Tap **Get Started**.
2. Enter your website domain (e.g., `netfiemart.com` or `https://netfiemart.com`). The app automatically constructs the REST API endpoint (`/wp-json/netfie-pay/v1/api` or `/netfie-pay/json/api`).
3. Enter a custom device name (e.g., `Merchant-Phone-1`).
4. Tap **Connect & Register**. A secure device ID and token will be generated and saved.

### 3. Soft Permission Setup
To ensure Google Play Protect compliance, permissions are requested softly from the **Settings** screen:
- **SMS Permission**: Required to read incoming payment SMS. Go to **Settings → Permissions & Background Setup → SMS Permission** and tap **Grant**.
- **Notifications**: Enable push notifications for instant verification alerts.
- **Battery Optimization**: Tap **Configure** in Settings to disable battery saver restrictions for Pay Checker.
- **Autostart**: For Xiaomi, Samsung, Vivo, and Oppo devices, follow the in-app **Autostart Guide** to enable background execution.

---

## 🛒 WooCommerce Plugin Setup

1. Upload the `pay-checker-plugin` folder to `/wp-content/plugins/` or install via WordPress Admin (`Plugins → Add New → Upload Plugin`).
2. Activate **Netfie Pay Checker** in WordPress Admin.
3. The plugin automatically creates the necessary database tables and registers the REST API route `/wp-json/netfie-pay/v1/api`.
4. Navigate to **Pay Checker** in WordPress Dashboard:
   - Configure payment methods (bKash, Nagad, Rocket, Upay numbers and instruction text).
   - View connected Android devices in **Device Management**.
   - Monitor live transaction logs and matched orders.

---

## 🛠️ Custom Integration (Laravel, Custom PHP, Other Platforms)

Pay Checker is platform-agnostic! Any web platform can receive real-time payment verification from the Android app using our standard REST API structure.

### Quick Integration Steps:
1. Expose a single POST endpoint on your server (e.g., `/api/netfie-pay`).
2. Support the standard actions: `connect`, `register_device`, `heartbeat`, `sms_transaction`, `sync`, `disconnect`.
3. Authenticate requests using headers:
   - `X-Device-ID`: Device unique ID
   - `X-Device-Token`: Secret token generated during registration
4. Process incoming `sms_transaction` actions by matching `trx_id`, `amount`, and `provider` with your database orders.

> 📖 **Complete Documentation**: Read [`DOCUMENTATION.md`](file:///DOCUMENTATION.md) for full API endpoint specifications, JSON schemas, matching logic algorithms, and copy-paste code snippets for **Laravel** and **Pure PHP**.

---

## 🔐 Security & Privacy

- **Data Privacy**: Only MFS payment notification SMS messages are parsed. Personal or unrelated SMS messages are completely ignored.
- **Device Authentication**: Every transaction request requires a valid `X-Device-ID` and `X-Device-Token`.
- **Anti-Fraud & Replay Protection**: Duplicate Transaction IDs (`trx_id`) are rejected by the matching engine.
- **HTTPS Required**: All communications between app and web server must use secure SSL/TLS connections.

---

## 📄 License & Copyright

Copyright © 2026 **Netfie** ([https://netfie.com](https://netfie.com)). All Rights Reserved.
