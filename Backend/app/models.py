from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
import uuid

class LineItemModel(BaseModel):
    name: str
    quantity: float = 1.0
    unit_price: float = 0.0
    total_price: float = 0.0
    category: Optional[str] = None

class PreparedTransactionCreate(BaseModel):
    title: str
    amount: float
    merchant: Optional[str] = None
    category: str = "Other"
    source: str = "auto_scan"  # email_auto_scan, sms_auto_scan, photo_background_scan
    confidence_score: float = 0.95
    currency: str = "USD"
    suggested_card_last4: Optional[str] = None
    suggested_account_last4: Optional[str] = None
    raw_text: Optional[str] = None
    line_items: List[LineItemModel] = []
    transaction_date: Optional[str] = None

class PreparedTransactionResponse(BaseModel):
    id: str
    title: str
    amount: float
    merchant: str
    category: str
    source: str
    status: str  # pending_review, approved, rejected
    confidence_score: float
    currency: str
    suggested_card_last4: Optional[str] = None
    suggested_account_last4: Optional[str] = None
    raw_text: Optional[str] = None
    line_items: List[LineItemModel] = []
    transaction_date: str
    created_at: str
    approved_at: Optional[str] = None

class EmailWebhookPayload(BaseModel):
    sender: str
    recipient: Optional[str] = None
    subject: str
    body_plain: Optional[str] = None
    body_html: Optional[str] = None
    raw_headers: Optional[str] = None

class SMSWebhookPayload(BaseModel):
    sender_number: Optional[str] = None
    message: str
    received_at: Optional[str] = None
    device_id: Optional[str] = None

class ApprovalRequest(BaseModel):
    override_amount: Optional[float] = None
    override_category: Optional[str] = None
    account_id: Optional[str] = None
    credit_card_id: Optional[str] = None
    notes: Optional[str] = None
