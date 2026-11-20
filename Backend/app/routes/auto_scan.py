from fastapi import APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks
from typing import Optional
from app.models import EmailWebhookPayload, SMSWebhookPayload
from app.gemini_engine import analyze_receipt_image, analyze_text_message
from app.database import insert_prepared_transaction, get_prepared_transaction_by_id
import io
from pypdf import PdfReader

router = APIRouter(prefix="/api/v1/auto-scan", tags=["Auto Scan & Webhooks"])

@router.post("/email")
async def handle_inbound_email(payload: EmailWebhookPayload):
    """
    Inbound webhook for automated email scanning.
    Compatible with SendGrid Inbound Parse, Mailgun, Postmark, and iOS Mail forwarders.
    """
    raw_content = f"Subject: {payload.subject}\nFrom: {payload.sender}\n\n{payload.body_plain or payload.body_html or ''}"
    parsed = await analyze_text_message(raw_content, source_type="email")
    
    prepared_data = {
        "title": parsed.get("title", f"Email: {payload.subject}"),
        "amount": parsed.get("amount", 0.0),
        "merchant": parsed.get("merchant", payload.sender),
        "category": parsed.get("category", "Bills & Subscriptions"),
        "source": "email_auto_scan",
        "confidence_score": parsed.get("confidence_score", 0.95),
        "currency": parsed.get("currency", "USD"),
        "suggested_card_last4": parsed.get("suggested_card_last4"),
        "suggested_account_last4": parsed.get("suggested_account_last4"),
        "raw_text": raw_content[:1500],
        "line_items": parsed.get("line_items", []),
        "transaction_date": parsed.get("transaction_date")
    }
    
    tx_id = insert_prepared_transaction(prepared_data)
    return {
        "status": "success",
        "message": "Email analyzed by Gemini and transaction prepared for iPhone review.",
        "prepared_transaction_id": tx_id,
        "details": prepared_data
    }

@router.post("/sms")
async def handle_inbound_sms(payload: SMSWebhookPayload):
    """
    Inbound webhook for automated bank SMS alerts.
    Can be called directly by iOS Personal Automations (Shortcuts) or SMS forwarding services.
    """
    parsed = await analyze_text_message(payload.message, source_type="sms")
    
    prepared_data = {
        "title": parsed.get("title", f"Alert from {payload.sender_number or 'Bank'}"),
        "amount": parsed.get("amount", 0.0),
        "merchant": parsed.get("merchant", "Bank Alert"),
        "category": parsed.get("category", "Other"),
        "source": "sms_auto_scan",
        "confidence_score": parsed.get("confidence_score", 0.95),
        "currency": parsed.get("currency", "USD"),
        "suggested_card_last4": parsed.get("suggested_card_last4"),
        "suggested_account_last4": parsed.get("suggested_account_last4"),
        "raw_text": payload.message,
        "line_items": parsed.get("line_items", []),
        "transaction_date": parsed.get("transaction_date")
    }
    
    tx_id = insert_prepared_transaction(prepared_data)
    return {
        "status": "success",
        "message": "Bank SMS alert parsed and transaction prepared.",
        "prepared_transaction_id": tx_id,
        "details": prepared_data
    }

@router.post("/receipt")
async def handle_receipt_upload(
    file: UploadFile = File(...),
    source_label: Optional[str] = Form("photo_background_scan")
):
    """
    Upload endpoint for automatic background receipt & invoice scanning.
    Supports JPEG, PNG, HEIC, and PDF.
    """
    file_bytes = await file.read()
    content_type = file.content_type or "image/jpeg"
    
    if content_type == "application/pdf":
        # Extract PDF text or process directly
        try:
            reader = PdfReader(io.BytesIO(file_bytes))
            extracted_text = "\n".join([page.extract_text() or "" for page in reader.pages])
            if extracted_text.strip():
                parsed = await analyze_text_message(extracted_text, source_type="pdf_invoice")
            else:
                # If scanned PDF image
                parsed = await analyze_receipt_image(file_bytes, mime_type="application/pdf")
        except Exception:
            parsed = await analyze_receipt_image(file_bytes, mime_type="application/pdf")
    else:
        parsed = await analyze_receipt_image(file_bytes, mime_type=content_type)
        
    prepared_data = {
        "title": parsed.get("title", f"Receipt from {parsed.get('merchant', 'Scanned Store')}"),
        "amount": parsed.get("amount", 0.0),
        "merchant": parsed.get("merchant", "Scanned Store"),
        "category": parsed.get("category", "Shopping"),
        "source": source_label,
        "confidence_score": parsed.get("confidence_score", 0.96),
        "currency": parsed.get("currency", "USD"),
        "suggested_card_last4": parsed.get("suggested_card_last4"),
        "suggested_account_last4": parsed.get("suggested_account_last4"),
        "raw_text": f"Scanned file: {file.filename}",
        "line_items": parsed.get("line_items", []),
        "transaction_date": parsed.get("transaction_date")
    }
    
    tx_id = insert_prepared_transaction(prepared_data)
    return {
        "status": "success",
        "message": "Receipt auto-scanned by Gemini and transaction prepared.",
        "prepared_transaction_id": tx_id,
        "details": prepared_data
    }

@router.post("/shortcut")
async def handle_ios_shortcut_ingestion(
    text: str = Form(...),
    source_type: Optional[str] = Form("sms")
):
    """
    Lightweight form endpoint optimized for iOS Personal Automations & Siri Shortcuts.
    """
    parsed = await analyze_text_message(text, source_type=source_type)
    
    prepared_data = {
        "title": parsed.get("title", f"Auto-Scanned {source_type.upper()}"),
        "amount": parsed.get("amount", 0.0),
        "merchant": parsed.get("merchant", "Quick Ingest"),
        "category": parsed.get("category", "Other"),
        "source": f"{source_type}_auto_scan",
        "confidence_score": parsed.get("confidence_score", 0.95),
        "currency": parsed.get("currency", "USD"),
        "suggested_card_last4": parsed.get("suggested_card_last4"),
        "suggested_account_last4": parsed.get("suggested_account_last4"),
        "raw_text": text,
        "line_items": parsed.get("line_items", []),
        "transaction_date": parsed.get("transaction_date")
    }
    
    tx_id = insert_prepared_transaction(prepared_data)
    return {
        "status": "success",
        "prepared_transaction_id": tx_id,
        "amount": prepared_data["amount"],
        "merchant": prepared_data["merchant"],
        "category": prepared_data["category"]
    }
