from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from app.models import PreparedTransactionResponse, ApprovalRequest
from app.database import (
    get_prepared_transactions,
    get_prepared_transaction_by_id,
    update_prepared_transaction_status,
    approve_all_pending_transactions,
    insert_prepared_transaction
)

router = APIRouter(prefix="/api/v1/prepared", tags=["Prepared Transactions"])

@router.get("", response_model=List[PreparedTransactionResponse])
async def list_prepared_transactions(status: Optional[str] = Query("pending_review")):
    """
    Returns transactions that have been auto-scanned and prepared by the backend.
    Default status: 'pending_review'.
    """
    txs = get_prepared_transactions(status=status if status != "all" else None)
    return txs

@router.get("/{tx_id}", response_model=PreparedTransactionResponse)
async def get_prepared_transaction(tx_id: str):
    tx = get_prepared_transaction_by_id(tx_id)
    if not tx:
        raise HTTPException(status_code=404, detail="Prepared transaction not found")
    return tx

@router.post("/{tx_id}/approve")
async def approve_transaction(tx_id: str, req: Optional[ApprovalRequest] = None):
    overrides = req.dict(exclude_unset=True) if req else None
    success = update_prepared_transaction_status(tx_id, "approved", overrides=overrides)
    if not success:
        raise HTTPException(status_code=404, detail="Prepared transaction not found")
    return {"status": "success", "message": "Transaction approved and merged into active ledger."}

@router.post("/{tx_id}/reject")
async def reject_transaction(tx_id: str):
    success = update_prepared_transaction_status(tx_id, "rejected")
    if not success:
        raise HTTPException(status_code=404, detail="Prepared transaction not found")
    return {"status": "success", "message": "Transaction rejected."}

@router.post("/batch/approve-all")
async def batch_approve():
    count = approve_all_pending_transactions()
    return {"status": "success", "approved_count": count}

@router.post("/dev/simulate-mock-prepared")
async def simulate_mock_prepared_transactions():
    """
    Development endpoint: Generates 3 realistic auto-scanned transactions (from Email, SMS, and Scanned Receipt)
    so you can test the iPhone Auto-Scan inbox immediately!
    """
    mock_items = [
        {
            "title": "Costco Wholesale Electronic Receipt",
            "amount": 182.45,
            "merchant": "Costco Wholesale #482",
            "category": "Groceries",
            "source": "email_auto_scan",
            "confidence_score": 0.98,
            "currency": "USD",
            "suggested_card_last4": "1008",
            "raw_text": "Thank you for shopping at Costco. Order Total: $182.45 charged to Visa ending in 1008 on 11/20/2026.",
            "line_items": [
                {"name": "Kirkland Organic Eggs 24ct", "quantity": 1, "unit_price": 7.99, "total_price": 7.99, "category": "Groceries"},
                {"name": "Organic Olive Oil 2L", "quantity": 1, "unit_price": 22.99, "total_price": 22.99, "category": "Pantry"},
                {"name": "Paper Towels 12ct", "quantity": 1, "unit_price": 24.99, "total_price": 24.99, "category": "Household"},
                {"name": "Choice Ribeye Steaks", "quantity": 1, "unit_price": 54.50, "total_price": 54.50, "category": "Meat"},
                {"name": "Kirkland Protein Bars", "quantity": 2, "unit_price": 19.99, "total_price": 39.98, "category": "Snacks"}
            ],
            "transaction_date": "2026-11-20"
        },
        {
            "title": "Chase Bank SMS Alert: Shell Oil",
            "amount": 48.75,
            "merchant": "Shell Oil Station",
            "category": "Transportation",
            "source": "sms_auto_scan",
            "confidence_score": 0.96,
            "currency": "USD",
            "suggested_card_last4": "9314",
            "raw_text": "Chase Alert: You made a $48.75 purchase at SHELL OIL on card ending 9314 at 1:15 PM.",
            "line_items": [
                {"name": "Regular Unleaded Gas (12.5 gal)", "quantity": 1, "unit_price": 48.75, "total_price": 48.75, "category": "Fuel"}
            ],
            "transaction_date": "2026-11-20"
        },
        {
            "title": "Uber Eats Delivery Receipt",
            "amount": 32.10,
            "merchant": "Chipotle Mexican Grill",
            "category": "Dining & Food",
            "source": "email_auto_scan",
            "confidence_score": 0.97,
            "currency": "USD",
            "suggested_card_last4": "3029",
            "raw_text": "Uber Eats Receipt: Your order from Chipotle Mexican Grill was delivered. Total: $32.10.",
            "line_items": [
                {"name": "Chicken Burrito Bowl", "quantity": 1, "unit_price": 12.80, "total_price": 12.80, "category": "Food"},
                {"name": "Chips & Guacamole", "quantity": 1, "unit_price": 5.40, "total_price": 5.40, "category": "Food"},
                {"name": "Delivery Fee & Tip", "quantity": 1, "unit_price": 13.90, "total_price": 13.90, "category": "Service"}
            ],
            "transaction_date": "2026-11-20"
        }
    ]
    
    created_ids = []
    for item in mock_items:
        cid = insert_prepared_transaction(item)
        created_ids.append(cid)
        
    return {
        "status": "success",
        "message": f"Created {len(created_ids)} simulated auto-scanned transactions.",
        "ids": created_ids
    }
