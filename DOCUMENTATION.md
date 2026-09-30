# Pay Checker - Technical Documentation & Integration Guide

**Version**: 1.0.0  
**Developer**: Netfie ([https://netfie.com](https://netfie.com))  
**Support Contact**: WhatsApp `+8801884189495` | Mobile `+8801772326146`  

---

## 📋 Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Android App Architecture & Soft Permissions](#2-android-app-architecture--soft-permissions)
3. [REST API Specification](#3-rest-api-specification)
   - [API Endpoint & Headers](#api-endpoint--headers)
   - [Action 1: connect](#action-1-connect)
   - [Action 2: register_device](#action-2-register_device)
   - [Action 3: sms_transaction](#action-3-sms_transaction)
   - [Action 4: heartbeat](#action-4-heartbeat)
   - [Action 5: sync](#action-5-sync)
   - [Action 6: get_pending](#action-6-get_pending)
   - [Action 7: get_payment](#action-7-get_payment)
   - [Action 8: verify_payment](#action-8-verify_payment)
   - [Action 9: device_status](#action-9-device_status)
   - [Action 10: disconnect](#action-10-disconnect)
4. [Payment Matching Logic Algorithm](#4-payment-matching-logic-algorithm)
5. [Implementation Guide for Custom Frameworks](#5-implementation-guide-for-custom-frameworks)
   - [Laravel Implementation](#laravel-implementation)
   - [Pure PHP Implementation](#pure-php-implementation)
6. [WooCommerce Plugin Technical Details](#6-woocommerce-plugin-technical-details)
7. [Security & Production Checklist](#7-security--production-checklist)

---

## 1. Architecture Overview

Pay Checker consists of two primary components:

```
┌───────────────────────────────────────┐          ┌───────────────────────────────────────┐
│          Android Phone                │          │        Merchant Web Application       │
│  (Receives bKash/Nagad/Rocket SMS)    │          │    (WooCommerce / Laravel / Custom)    │
│                                       │          │                                       │
│  ┌─────────────────────────────────┐  │  HTTPS   │  ┌─────────────────────────────────┐  │
│  │  SmsReceiver (Broadcast)        │  │  POST    │  │  REST API Endpoint              │  │
│  └────────────────┬────────────────┘  │─────────>│  │  (/wp-json/netfie-pay/v1/api)  │  │
│                   │                   │  JSON    │  └────────────────┬────────────────┘  │
│  ┌────────────────▼────────────────┐  │          │                   │                   │
│  │  Parser Engine (RegEx)          │  │          │  ┌────────────────▼────────────────┐  │
│  └────────────────┬────────────────┘  │          │  │  Matching Engine                │  │
│                   │                   │          │  └────────────────┬────────────────┘  │
│  ┌────────────────▼────────────────┐  │          │                   │                   │
│  │  SmsListenerService & Sync      │  │          │  ┌────────────────▼────────────────┐  │
│  └─────────────────────────────────┘  │          │  │  Database & Order Status       │  │
└───────────────────────────────────────┘          │  └─────────────────────────────────┘  │
                                                   └───────────────────────────────────────┘
```

---

## 2. Android App Architecture & Soft Permissions

### 2.1 Technology Stack
- **Framework**: Flutter 3.x (Dart 3.x)
- **State Management**: Provider (`AuthProvider`, `PaymentsProvider`, `SettingsProvider`, `LogsProvider`)
- **Native Android Handler**: Kotlin (`MainActivity.kt`, `SmsReceiver.kt`)
- **Background Engine**: Workmanager (`BackgroundService`)
- **Local Database**: Sqflite (`OfflineQueueService`)

### 2.2 Google Play Protect & Soft Permission Strategy
To pass Google Play Protect security policies without triggering installation or runtime security flags:
1. **Manifest Restrictions**: Unnecessary dangerous permissions like `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` are completely removed from `AndroidManifest.xml`.
2. **Zero Startup Popups**: Permission request dialogs are never called on app startup or onboarding.
3. **User-Initiated Runtime Requests**: All permission requests (`RECEIVE_SMS`, `POST_NOTIFICATIONS`) and battery optimization settings are explicitly triggered by the user from **Settings → Permissions & Background Setup**.

---

## 3. REST API Specification

### API Endpoint & Headers

#### Base URL Pattern
- **WooCommerce / WordPress**: `https://yourdomain.com/wp-json/netfie-pay/v1/api`
- **Laravel / Custom API**: `https://yourdomain.com/api/netfie-pay` (or any custom URL endpoint)

#### Custom HTTP Headers
All API requests sent from the Android app contain JSON body and the following optional HTTP headers:

| Header Name | Type | Description |
| :--- | :--- | :--- |
| `Content-Type` | `string` | Always `application/json` |
| `Accept` | `string` | Always `application/json` |
| `X-Device-ID` | `string` | Device unique identifier (e.g., `NF-ANDROID-89102`) |
| `X-Device-Token` | `string` | Secret token generated during device registration |
| `X-Action` | `string` | Optional fallback header for action name |

---

### Action 1: `connect`
Verifies connection and retrieves site configuration when the user enters the domain in the app.

- **Authentication Required**: No

#### Request JSON
```json
{
  "action": "connect",
  "app_version": "1.0.0"
}
```

#### Success Response JSON (HTTP 200)
```json
{
  "status": "success",
  "success": true,
  "message": "Pay Checker API endpoint active and ready.",
  "data": {
    "site_name": "Netfie Mart",
    "domain": "netfiemart.com",
    "plugin_version": "1.0.0",
    "api_version": "1.0.0",
    "supported_providers": ["bkash", "nagad", "rocket", "upay"]
  }
}
```

---

### Action 2: `register_device`
Registers a new Android device with the server and generates a secret `device_token`.

- **Authentication Required**: No (requires valid `device_id`)

#### Request JSON
```json
{
  "action": "register_device",
  "device_id": "NF-ANDROID-89102",
  "device_name": "Merchant Phone 1",
  "device_model": "Samsung Galaxy A54",
  "os_version": "Android 14"
}
```

#### Success Response JSON (HTTP 200)
```json
{
  "status": "success",
  "success": true,
  "message": "Device registered successfully.",
  "data": {
    "device_id": "NF-ANDROID-89102",
    "device_token": "nf_dev_a8f921bc901e4578128490a1b2c3d4e5",
    "status": "active"
  }
}
```

---

### Action 3: `sms_transaction`
Sent by the Android app immediately when an MFS payment SMS is received.

- **Authentication Required**: Yes (`X-Device-ID` & `X-Device-Token` headers)

#### Request JSON
```json
{
  "action": "sms_transaction",
  "provider": "bkash",
  "trx_id": "BLM890123A",
  "amount": 1500.00,
  "sender": "bKash",
  "raw_sms": "You have received Tk 1,500.00 from 01711223344. Fee Tk 0.00. Balance Tk 25,400.00. TrxID BLM890123A at 30/09/2026 14:20",
  "received_at": "2026-09-30T14:20:00.000Z"
}
```

#### Verified Match Response JSON (HTTP 200)
```json
{
  "status": "success",
  "success": true,
  "message": "Payment verified and order status updated.",
  "data": {
    "id": "1042",
    "trx_id": "BLM890123A",
    "provider": "bkash",
    "amount": 1500.00,
    "sender": "01711223344",
    "status": "verified",
    "order_id": "8542",
    "received_at": "2026-09-30 14:20:00"
  }
}
```

#### Unmatched Response JSON (HTTP 200)
```json
{
  "status": "success",
  "success": true,
  "message": "Transaction recorded as unmatched.",
  "data": {
    "id": "1043",
    "trx_id": "BLM890123A",
    "provider": "bkash",
    "amount": 1500.00,
    "sender": "01711223344",
    "status": "unmatched",
    "order_id": null,
    "received_at": "2026-09-30 14:20:00"
  }
}
```

#### Duplicate Transaction Response JSON (HTTP 200)
```json
{
  "status": "error",
  "success": false,
  "message": "Duplicate transaction detected.",
  "data": {
    "trx_id": "BLM890123A",
    "status": "duplicate"
  }
}
```

---

### Action 4: `heartbeat`
Periodic ping sent by background tasks to update device online status and last sync time.

- **Authentication Required**: Yes

#### Request JSON
```json
{
  "action": "heartbeat",
  "device_id": "NF-ANDROID-89102",
  "timestamp": "2026-09-30T14:30:00.000Z"
}
```

#### Success Response JSON (HTTP 200)
```json
{
  "status": "success",
  "success": true,
  "message": "Heartbeat acknowledged",
  "data": {
    "timestamp": "2026-09-30 14:30:00"
  }
}
```

---

### Action 5: `sync`
Retrieves recent transaction history from server to update Flutter local state.

- **Authentication Required**: Yes

#### Request JSON
```json
{
  "action": "sync"
}
```

#### Success Response JSON (HTTP 200)
```json
{
  "status": "success",
  "success": true,
  "message": "Sync completed",
  "data": {
    "payments": [
      {
        "id": "1042",
        "trx_id": "BLM890123A",
        "provider": "bkash",
        "amount": 1500.00,
        "sender": "01711223344",
        "status": "verified",
        "order_id": "8542",
        "received_at": "2026-09-30 14:20:00"
      }
    ]
  }
}
```

---

### Action 6: `get_pending`
Gets pending orders awaiting payment verification.

- **Authentication Required**: Yes

#### Request JSON
```json
{
  "action": "get_pending"
}
```

#### Success Response JSON (HTTP 200)
```json
{
  "status": "success",
  "success": true,
  "message": "Pending orders retrieved",
  "data": {
    "orders": [
      {
        "order_id": 8542,
        "total": "1500.00",
        "customer_name": "Rahim Uddin",
        "trx_id": "BLM890123A",
        "provider": "bkash",
        "created_at": "2026-09-30 14:15:00"
      }
    ]
  }
}
```

---

### Action 7: `get_payment`
Fetch single transaction details by `trx_id` or `id`.

#### Request JSON
```json
{
  "action": "get_payment",
  "trx_id": "BLM890123A"
}
```

---

### Action 8: `verify_payment`
Manual verification request triggered from admin dashboard or device dialog.

#### Request JSON
```json
{
  "action": "verify_payment",
  "provider": "bkash",
  "trx_id": "BLM890123A",
  "amount": 1500.00,
  "sender": "01711223344"
}
```

---

### Action 9: `device_status`
Returns status of connected device (`active`, `inactive`, `revoked`).

#### Request JSON
```json
{
  "action": "device_status"
}
```

---

### Action 10: `disconnect`
Revokes device token and disconnects device.

#### Request JSON
```json
{
  "action": "disconnect"
}
```

---

## 4. Payment Matching Logic Algorithm

The Pay Checker Matching Engine operates on the following logical sequence:

```
[ Incoming SMS Transaction ]
            │
            ▼
[ Is TrxID already in Database? ] ─── YES ───> [ Return Duplicate Status ]
            │
           NO
            ▼
[ Query Pending Orders Matching: ]
   1. Customer Submitted TrxID == Received TrxID (Exact TrxID Match)
   2. OR Order Total Amount == Received Amount AND Order Status is 'Pending'
            │
            ├───────────────────────────────────────────┐
            │ Match Found                               │ No Match Found
            ▼                                           ▼
[ Mark Order as Processing / Completed ]      [ Save to Database as 'unmatched' ]
[ Save Transaction as 'verified' ]            [ Send Unmatched Alert ]
[ Return Success & Order ID ]
```

---

## 5. Implementation Guide for Custom Frameworks

### Laravel Implementation

#### 1. Route Definition (`routes/api.php`)
```php
use App\Http\Controllers\Api\PayCheckerController;
use Illuminate\Support\Facades\Route;

Route::post('/netfie-pay', [PayCheckerController::class, 'handleRequest']);
```

#### 2. Migration (`database/migrations/create_pay_checker_tables.php`)
```php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('pay_checker_devices', function (Blueprint $table) {
            $table->id();
            $table->string('device_id')->unique();
            $table->string('device_name');
            $table->string('device_model')->nullable();
            $table->string('os_version')->nullable();
            $table->string('device_token');
            $table->string('status')->default('active');
            $table->timestamp('last_sync')->nullable();
            $table->timestamps();
        });

        Schema::create('pay_checker_payments', function (Blueprint $table) {
            $table->id();
            $table->string('provider'); // bkash, nagad, rocket, upay
            $table->string('trx_id')->unique();
            $table->decimal('amount', 10, 2);
            $table->string('sender')->nullable();
            $table->text('raw_sms')->nullable();
            $table->string('status')->default('unmatched'); // verified, unmatched, duplicate
            $table->unsignedBigInteger('order_id')->nullable();
            $table->string('device_id')->nullable();
            $table->timestamp('received_at');
            $table->timestamps();
        });
    }

    public function down(): void {
        Schema::dropIfExists('pay_checker_payments');
        Schema::dropIfExists('pay_checker_devices');
    }
};
```

#### 3. Controller (`app/Http/Controllers/Api/PayCheckerController.php`)
```php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class PayCheckerController extends Controller {

    public function handleRequest(Request $request) {
        $action = $request->input('action', $request->header('X-Action', 'connect'));
        $deviceId = $request->header('X-Device-ID', $request->input('device_id'));
        $deviceToken = $request->header('X-Device-Token', $request->input('device_token'));

        switch ($action) {
            case 'connect':
                return response()->json([
                    'status' => 'success',
                    'success' => true,
                    'message' => 'Pay Checker API Active',
                    'data' => [
                        'site_name' => config('app.name'),
                        'domain' => parse_url(config('app.url'), PHP_URL_HOST),
                        'supported_providers' => ['bkash', 'nagad', 'rocket', 'upay']
                    ]
                ]);

            case 'register_device':
                $token = 'nf_dev_' . Str::random(32);
                DB::table('pay_checker_devices')->updateOrInsert(
                    ['device_id' => $deviceId],
                    [
                        'device_name' => $request->input('device_name', 'Android-Device'),
                        'device_model' => $request->input('device_model', 'Android'),
                        'os_version' => $request->input('os_version', '14'),
                        'device_token' => $token,
                        'status' => 'active',
                        'last_sync' => now(),
                        'updated_at' => now(),
                    ]
                );

                return response()->json([
                    'status' => 'success',
                    'success' => true,
                    'message' => 'Device registered successfully',
                    'data' => [
                        'device_id' => $deviceId,
                        'device_token' => $token,
                        'status' => 'active'
                    ]
                ]);

            case 'sms_transaction':
                $this->authenticateDevice($deviceId, $deviceToken);
                return $this->processSmsTransaction($request, $deviceId);

            case 'heartbeat':
                $this->authenticateDevice($deviceId, $deviceToken);
                DB::table('pay_checker_devices')->where('device_id', $deviceId)->update(['last_sync' => now()]);
                return response()->json(['status' => 'success', 'success' => true, 'message' => 'Heartbeat acknowledged']);

            default:
                return response()->json(['status' => 'error', 'success' => false, 'message' => 'Invalid action'], 400);
        }
    }

    private function authenticateDevice($deviceId, $deviceToken) {
        if (!$deviceId || !$deviceToken) {
            response()->json(['status' => 'error', 'success' => false, 'message' => 'Unauthenticated'], 401)->send();
            exit;
        }

        $device = DB::table('pay_checker_devices')
            ->where('device_id', $deviceId)
            ->where('device_token', $deviceToken)
            ->where('status', 'active')
            ->first();

        if (!$device) {
            response()->json(['status' => 'error', 'success' => false, 'message' => 'Invalid Device Credentials'], 401)->send();
            exit;
        }
    }

    private function processSmsTransaction(Request $request, $deviceId) {
        $trxId = trim($request->input('trx_id'));
        $amount = (float) $request->input('amount');
        $provider = strtolower(trim($request->input('provider')));
        $sender = trim($request->input('sender'));

        // Check duplicate
        $existing = DB::table('pay_checker_payments')->where('trx_id', $trxId)->first();
        if ($existing) {
            return response()->json([
                'status' => 'error',
                'success' => false,
                'message' => 'Duplicate transaction',
                'data' => ['trx_id' => $trxId, 'status' => 'duplicate']
            ]);
        }

        // Match with pending orders in your application
        $order = DB::table('orders')
            ->where('status', 'pending')
            ->where('total_amount', $amount)
            ->where(function ($query) use ($trxId, $sender) {
                $query->where('user_trx_id', $trxId)
                      ->orWhere('user_phone', $sender);
            })->first();

        $status = $order ? 'verified' : 'unmatched';
        $orderId = $order ? $order->id : null;

        if ($order) {
            DB::table('orders')->where('id', $order->id)->update(['status' => 'completed', 'paid_at' => now()]);
        }

        $id = DB::table('pay_checker_payments')->insertGetId([
            'provider' => $provider,
            'trx_id' => $trxId,
            'amount' => $amount,
            'sender' => $sender,
            'raw_sms' => $request->input('raw_sms'),
            'status' => $status,
            'order_id' => $orderId,
            'device_id' => $deviceId,
            'received_at' => now(),
            'created_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'success' => true,
            'message' => $order ? 'Payment verified and order completed' : 'Transaction saved as unmatched',
            'data' => [
                'id' => (string) $id,
                'trx_id' => $trxId,
                'provider' => $provider,
                'amount' => $amount,
                'sender' => $sender,
                'status' => $status,
                'order_id' => (string) $orderId
            ]
        ]);
    }
}
```

---

### Pure PHP Implementation

#### Single File Script (`api.php`)
```php
<?php
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');

$raw = file_get_contents('php://input');
$data = json_decode($raw, true) ?? $_REQUEST;

$action = $data['action'] ?? $_SERVER['HTTP_X_ACTION'] ?? 'connect';
$deviceId = $_SERVER['HTTP_X_DEVICE_ID'] ?? $data['device_id'] ?? '';
$deviceToken = $_SERVER['HTTP_X_DEVICE_TOKEN'] ?? $data['device_token'] ?? '';

$pdo = new PDO('mysql:host=localhost;dbname=your_database;charset=utf8mb4', 'db_user', 'db_password');

if ($action === 'connect') {
    echo json_encode([
        'status' => 'success',
        'success' => true,
        'message' => 'Pay Checker PHP API active',
        'data' => [
            'site_name' => 'Custom PHP Store',
            'domain' => $_SERVER['HTTP_HOST'],
            'supported_providers' => ['bkash', 'nagad', 'rocket', 'upay']
        ]
    ]);
    exit;
}

if ($action === 'register_device') {
    $token = 'nf_dev_' . bin2hex(random_bytes(16));
    $stmt = $pdo->prepare("INSERT INTO pay_checker_devices (device_id, device_token, device_name, status) VALUES (?, ?, ?, 'active') ON DUPLICATE KEY UPDATE device_token = ?, status = 'active'");
    $stmt->execute([$deviceId, $token, $data['device_name'] ?? 'Android Phone', $token]);

    echo json_encode([
        'status' => 'success',
        'success' => true,
        'data' => ['device_id' => $deviceId, 'device_token' => $token, 'status' => 'active']
    ]);
    exit;
}

// Authenticate
$stmt = $pdo->prepare("SELECT * FROM pay_checker_devices WHERE device_id = ? AND device_token = ? AND status = 'active'");
$stmt->execute([$deviceId, $deviceToken]);
if (!$stmt->fetch()) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'success' => false, 'message' => 'Unauthorized device']);
    exit;
}

if ($action === 'sms_transaction') {
    $trxId = trim($data['trx_id']);
    $amount = floatval($data['amount']);
    $provider = strtolower($data['provider']);
    $sender = trim($data['sender']);

    // Save transaction
    $stmt = $pdo->prepare("INSERT INTO pay_checker_payments (provider, trx_id, amount, sender, raw_sms, status) VALUES (?, ?, ?, ?, ?, 'unmatched')");
    $stmt->execute([$provider, $trxId, $amount, $sender, $data['raw_sms'] ?? '']);

    echo json_encode([
        'status' => 'success',
        'success' => true,
        'message' => 'Transaction saved',
        'data' => ['trx_id' => $trxId, 'status' => 'unmatched', 'amount' => $amount]
    ]);
    exit;
}
```

---

## 6. WooCommerce Plugin Technical Details

The included WooCommerce plugin (`pay-checker-plugin/`) automatically handles gateway registration, order creation, and API processing:
- **Plugin Directory**: `pay-checker-plugin/`
- **Main Plugin File**: `pay-checker.php`
- **Database Tables**:
  - `wp_pay_checker_payments`: Stores raw and parsed payment SMS records.
  - `wp_pay_checker_devices`: Stores registered Android device tokens.
  - `wp_pay_checker_logs`: Internal system logs.
- **REST Route**: `/wp-json/netfie-pay/v1/api`

---

## 7. Security & Production Checklist

1. **Enforce HTTPS**: Always use SSL certificates on your web server (`https://`).
2. **Device Token Verification**: Never disable device authentication in production.
3. **Prepared Statements / ORM**: Use PDO prepared statements or Eloquent ORM to prevent SQL injection.
4. **Duplicate TrxID Protection**: Maintain a `UNIQUE` index on `trx_id` in your database.
5. **Keep App Active**: Grant battery optimization exemption and autostart on merchant Android phones to ensure background continuity.

---

**Developed with ❤️ by Netfie**  
Website: [https://netfie.com](https://netfie.com)
