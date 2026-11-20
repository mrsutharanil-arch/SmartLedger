# SmartLedger: Personal AI Accounting & Wealth Manager for iPhone (iOS) & Auto-Scan Backend

> A complete personal accounting system consisting of a native **iOS iPhone App (SwiftUI, VisionKit, AppIntents)** and a high-performance **Auto-Scan Backend (FastAPI, Google Gemini AI)** for automated background receipt scanning, SMS alert parsing, email forwarding, account balances, credit cards, bills, and investment portfolios.

---

## ⚡ What's New: Auto-Scan & Background Transaction Preparation

SmartLedger now features **automated background transaction preparation**:

```
[Inbound Email Receipt]  ──┐
[Bank Alert SMS / Push]  ──┼──> [Auto-Scan Backend (FastAPI + Gemini)]
[Background Camera Roll] ──┘                 │
                                             ▼
                             [Gemini 2.5 Flash Structured OCR]
                                             │
                                             ▼
                             [Staged & Prepared Transaction]
                                             │
                                             ▼
                        [iPhone iOS App: Auto-Scan Inbox]
                                             │
                           [1-Tap Swipe to Approve & Merge]
                                             │
                                             ▼
                        [Ledger Updated + Balance Auto-Deducted]
```

1. **Inbound Webhooks**:
   - `POST /api/v1/auto-scan/email`: Inbound email webhook (SendGrid, Mailgun, Postmark, AWS SES, or IMAP poller) that extracts invoice bodies and PDF receipts.
   - `POST /api/v1/auto-scan/sms`: Inbound webhook for bank SMS alerts.
   - `POST /api/v1/auto-scan/receipt`: Background upload endpoint for receipts and invoices.
   - `POST /api/v1/auto-scan/shortcut`: Lightweight form endpoint designed for Apple Personal Automations.
2. **Apple Shortcuts & AppIntents**:
   - Native iOS `AutoScanMessageIntent` and `SmartLedgerShortcuts` provider: Trigger automations directly in the Apple Shortcuts app when an SMS arrives from your bank or when a screenshot is taken.
3. **iOS BackgroundTasks (`BGAppRefreshTask`)**:
   - Periodically queries the backend in the background when the iPhone is charging or connected to Wi-Fi.
   - Posts native Apple push notifications (`UNUserNotificationCenter`) alert: *"2 new transactions auto-prepared from bank alerts. Tap to review."*
4. **Prepared Transactions Review Tray**:
   - Interactive review cards on iOS Dashboard and Scan Hub.
   - See AI confidence score, extracted line items, and auto-matched credit card or checking account.
   - 1-tap "Approve & Deduct" or "Approve All" to finalize into the active ledger.

---

## 📱 iOS App Capabilities

### 1. Ingestion & Scanning
- **Camera Document & Receipt Scanner**: Apple's native **VisionKit** (`VNDocumentCameraViewController`) with Gemini multimodal vision.
- **Bank SMS Parser**: Instant regex extraction + Gemini fallback for Chase, Amex, Apple Pay, Bank of America, HDFC, SBI, etc.
- **Auto-Scan Inbox**: Dedicated tray for transactions prepared automatically by the backend.

### 2. Bank Accounts & Credit Cards
- **Accounts**: Checking, Savings, Cash, Wallets with real-time balance calculations.
- **Credit Card Deck**: Apple Wallet-style visual cards with EMV chip, APR, statement closing dates, due date countdowns, and real-time **Credit Utilization Bars** (>30% alert).
- **Pay Card Action**: Direct modal to make card payments from selected bank accounts.

### 3. Bills & Subscriptions
- **Recurring Bills Tracker**: Utilities, rent, streaming, loan EMIs with due date reminders.
- **Auto-Pay Indicators**: Distinguishes automated bank debits from manual bills.
- **Mark Paid**: 1-tap logging into the ledger.

### 4. Investments & Net Worth
- **Multi-Asset Portfolio**: Equities, ETFs, Crypto, Mutual Funds, Bonds.
- **Asset Allocation**: Visual distribution bars.
- **Net Worth**: `(Cash + Investments) - Credit Card Debt`.

### 5. Gemini AI Advisor
- **Conversational Chat Assistant**: Grounded in live balances, pending bills, and spending patterns.
- **Financial Health Index (0-100)**: Real-time score based on credit utilization, savings rate, and bill reliability.
- **Proactive AI Alerts**: Spending anomaly detection and cost-cutting advice.

---

## 🏗️ Project Structure

```
SmartLedger/
├── Backend/                            # Auto-Scan Backend Service (FastAPI + Python)
│   ├── app/
│   │   ├── main.py                     # FastAPI server & CORS setup
│   │   ├── models.py                   # Pydantic schemas (PreparedTransaction, Webhooks)
│   │   ├── database.py                 # SQLite storage for staged transactions
│   │   ├── gemini_engine.py            # Gemini 2.5 Flash multimodal & text client
│   │   └── routes/
│   │       ├── auto_scan.py            # Email, SMS & Receipt upload webhooks
│   │       └── prepared_transactions.py# Prepared inbox, approval & rejection APIs
│   ├── requirements.txt                # Python dependencies
│   ├── Dockerfile                      # Container deployment
│   ├── .env.example                    # Gemini API Key & settings template
│   └── README.md                       # Backend documentation & Shortcuts guide
│
├── SmartLedger/                        # Native iOS Application (Swift / SwiftUI)
│   ├── App/
│   │   └── SmartLedgerApp.swift        # App entry & BackgroundTasks registration
│   ├── AppIntents/
│   │   └── AutoScanMessageIntent.swift # Apple Shortcuts AppIntents integration
│   ├── Models/
│   │   ├── Account.swift               # Checking, Savings, Cash models
│   │   ├── CreditCard.swift            # Credit cards & utilization metrics
│   │   ├── PreparedTransaction.swift   # Auto-scanned prepared transaction model
│   │   ├── Transaction.swift           # Ledger transactions
│   │   ├── Bill.swift                  # Recurring bills & subscriptions
│   │   ├── Investment.swift            # Portfolio assets
│   │   ├── AIInsight.swift             # Gemini proactive insights
│   │   └── ParsedReceipt.swift         # Extracted receipt line items
│   ├── Services/
│   │   ├── BackendSyncService.swift    # Connects iPhone to Auto-Scan Backend
│   │   ├── BackgroundScanManager.swift # BGAppRefreshTask & Photo monitoring
│   │   ├── GeminiAPIService.swift      # On-device Gemini client
│   │   ├── DocumentScannerService.swift# VisionKit camera document scanner
│   │   ├── SMSParserService.swift      # Bank SMS regex parser
│   │   ├── BiometricAuthService.swift  # Face ID / Touch ID gatekeeper
│   │   └── DataStore.swift             # Central Observable state & local persistence
│   ├── Views/
│   │   ├── MainTabView.swift           # 5-tab root navigation
│   │   ├── Dashboard/
│   │   │   └── DashboardView.swift     # Net Worth, Auto-Scan Banner, Cash Flow
│   │   ├── Ingestion/
│   │   │   ├── ScanHubView.swift       # Scanning center
│   │   │   ├── PreparedTransactionsInboxView.swift # Auto-Scan review & approval inbox
│   │   │   └── ParsedReceiptReviewView.swift       # Manual receipt review sheet
│   │   ├── Accounts/
│   │   │   └── AccountsView.swift      # Banks, Credit Cards & Card Pay modal
│   │   ├── Bills/
│   │   │   └── BillsTrackerView.swift  # Bills & subscriptions tracker
│   │   ├── Investments/
│   │   │   └── InvestmentsView.swift   # Portfolio value & asset allocation
│   │   ├── AIAdvisor/
│   │   │   └── AIAdvisorView.swift     # Gemini chat & Health Score
│   │   └── Settings/
│   │       └── SettingsView.swift      # Gemini Key, Backend Server URL, Face ID
│   └── Info.plist                      # Camera, Face ID, BackgroundModes permissions
```

---

## 🚀 Running the System

### Step 1: Run the Auto-Scan Backend
```bash
cd F:\ios\SmartLedger\Backend
pip install -r requirements.txt
cp .env.example .env   # Add your GEMINI_API_KEY
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
API Documentation will be live at: `http://localhost:8000/docs`.

### Step 2: Run the iOS App in Xcode
1. Open **Xcode** on your Mac.
2. Select **File > New > Project...** -> **iOS > App** (named `SmartLedger`).
3. Drag the [`SmartLedger`](file:///f:/ios/SmartLedger/SmartLedger) source folder into Xcode.
4. Set the Bundle Identifier to `com.smartledger.app`.
5. Under **Signing & Capabilities**, add **Background Modes** (check *Background fetch* and *Background processing*).
6. Press **Cmd + R** to run on your iPhone or Simulator!
