# SmartLedger: Personal AI Accounting & Wealth Manager

<div align="center">
  <img src="logo.png" width="128" height="128" alt="SmartLedger Logo" />
  <h2>SmartLedger</h2>
  <p><b>An Official Financial Engineering Solution by Suthar Anil Arch</b></p>
  <p><i>Automated Mobile Personal Accounting, Receipt Scanning & Gemini AI Financial Intelligence</i></p>
</div>

---

## 🏢 Company & Organization Information

- **Organization / Developer**: Suthar Anil Arch Tech
- **Legal Entity**: Suthar Anil Architecture & Financial Solutions
- **Industry**: Software Architecture, Personal Finance & Accounting Technology
- **Official Contact**: [mr.sutharanil@gmail.com](mailto:mr.sutharanil@gmail.com)
- **GitHub Repository**: [https://github.com/mrsutharanil-arch/SmartLedger](https://github.com/mrsutharanil-arch/SmartLedger)
- **Tax Identifier / VAT**: `TAX-ID: 24AABCS1492Z1`
- **Registration**: `REG-2026-IN-9841`
- **Location**: Gujarat, India

*Note: All company details, tax identifiers, and contact numbers can be dynamically updated inside the iOS app via **Settings > Company Profile & Branding**.*

---

## ⚡ What is SmartLedger?

SmartLedger is a personal accounting system combining a **native iPhone App (SwiftUI, VisionKit, AppIntents)** with an **Auto-Scan Backend (FastAPI, Google Gemini AI)**:

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

---

## 📱 iOS App Highlights

### 1. Company Branding & Corporate Letterheads
- **Dynamic Header**: Displays your corporate branding badge and tax identifier on the Dashboard.
- **Statement Letterheads**: Generates official statements of accounts with company letterhead, tax registration numbers, and financial position summaries.

### 2. Multi-Source Ingestion & Auto-Scan
- **VisionKit Camera Scanner**: Scans paper receipts, invoices, and checks with Gemini multimodal vision.
- **SMS Bank Alert Parser**: Instant regex extraction + Gemini fallback for transaction notifications.
- **Auto-Scan Prepared Inbox**: Review incoming background transactions and approve them in 1 tap.

### 3. Bank Accounts & Credit Card Deck
- **Accounts**: Checking, Savings, Cash, Digital Wallets.
- **Interactive Credit Cards**: EMV chip styling, statement closing dates, due date countdowns, and real-time **Credit Utilization Bars** (>30% alert).
- **Pay Card**: 1-tap modal to make credit card payments and auto-log transactions.

### 4. Bills & Subscriptions
- Recurring utility bills, rent, streaming, loan EMIs with due date alerts.
- Auto-pay status flags and 1-tap "Mark as Paid".

### 5. Investments & Net Worth
- Equities, ETFs, Crypto, Mutual Funds, Bonds.
- Asset allocation breakdown.
- Net Worth formula: `(Cash Balances + Investments) - Credit Debt`.

### 6. Gemini AI Advisor & Financial Health Index
- Conversational financial chat grounded in your live accounts.
- Autonomous Financial Health Index (0–100).
- Anomaly alerts for high credit utilization or spending spikes.

---

## 🚀 Building & Running

### 1. Build the iOS App on Mac / Xcode
```bash
git clone https://github.com/mrsutharanil-arch/SmartLedger.git
cd SmartLedger
brew install xcodegen
xcodegen generate
open SmartLedger.xcodeproj
```

### 2. Run the Auto-Scan Backend
```bash
cd Backend
pip install -r requirements.txt
cp .env.example .env
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
API Documentation live at: `http://localhost:8000/docs`.
