# SmartLedger Auto-Scan Backend Service

This backend service runs in the cloud or on a local server/Mac to perform **continuous automatic background scanning** of incoming bank SMS messages, forwarded receipt emails, and background camera uploads. It uses **Google Gemini 2.5 Flash** to analyze documents and prepare structured transactions waiting for 1-tap confirmation on your iPhone.

---

## ⚡ Quick Start

### 1. Install Dependencies
```bash
cd Backend
python -m venv venv
# On Windows:
.\venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### 2. Configure Environment
Copy `.env.example` to `.env` and enter your Gemini API Key:
```bash
cp .env.example .env
```

### 3. Run the Server
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
API Documentation will be live at: `http://localhost:8000/docs`

---

## 🔗 How Auto-Scan Connects to iPhone

### 1. Inbound Email Auto-Scan Webhook (`POST /api/v1/auto-scan/email`)
- Setup an inbound email address like `receipts@yourdomain.com` (using SendGrid Inbound Parse, Mailgun, Postmark, or AWS SES).
- Forward your Amazon, Uber, utility, or flight receipts to that address.
- The webhook automatically extracts the invoice details with Gemini, prepares the transaction, and pushes it to your iPhone's **Prepared Transactions Inbox**.

### 2. iOS Personal Automations (Shortcuts) (`POST /api/v1/auto-scan/shortcut`)
- In the iPhone **Shortcuts** app:
  1. Go to **Automation** tab -> Create New Automation.
  2. Select **Message** -> When I receive a message containing words like "spent", "debited", "charged", "purchase".
  3. Action: **Get Contents of URL** (`POST http://<your-server-ip>:8000/api/v1/auto-scan/shortcut` with field `text = Shortcut Input`).
  4. Turn off *"Ask Before Running"*.
- **Result**: Every time your bank texts you an alert, your backend automatically parses it and prepares the transaction without you even opening the app!

### 3. iPhone Ingestion Sync
- The iPhone app periodically pulls `GET /api/v1/prepared` using iOS `BackgroundTasks` (`BGAppRefreshTask`).
- Transactions appear in the **"Prepared by Auto-Scan"** tray on your Dashboard.
- Simply tap **Approve** or swipe right to deduct it from the appropriate card/account balance and add it to your ledger.
