import json
import sqlite3
import os
from typing import List, Optional
from datetime import datetime
import uuid

DB_FILE = os.getenv("DATABASE_PATH", "smartledger_backend.db")

def get_connection():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS prepared_transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        merchant TEXT,
        category TEXT NOT NULL,
        source TEXT NOT NULL,
        status TEXT NOT NULL, -- pending_review, approved, rejected
        confidence_score REAL NOT NULL,
        currency TEXT NOT NULL,
        suggested_card_last4 TEXT,
        suggested_account_last4 TEXT,
        raw_text TEXT,
        line_items_json TEXT,
        transaction_date TEXT,
        created_at TEXT NOT NULL,
        approved_at TEXT
    )
    """)
    conn.commit()
    conn.close()

def insert_prepared_transaction(data: dict) -> str:
    conn = get_connection()
    cursor = conn.cursor()
    tx_id = str(uuid.uuid4())
    now_iso = datetime.utcnow().isoformat()
    
    line_items_json = json.dumps(data.get("line_items", []))
    
    cursor.execute("""
    INSERT INTO prepared_transactions (
        id, title, amount, merchant, category, source, status,
        confidence_score, currency, suggested_card_last4, suggested_account_last4,
        raw_text, line_items_json, transaction_date, created_at, approved_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        tx_id,
        data.get("title", "Scanned Transaction"),
        float(data.get("amount", 0.0)),
        data.get("merchant", data.get("title", "Unknown Merchant")),
        data.get("category", "Other"),
        data.get("source", "auto_scan"),
        "pending_review",
        float(data.get("confidence_score", 0.95)),
        data.get("currency", "USD"),
        data.get("suggested_card_last4"),
        data.get("suggested_account_last4"),
        data.get("raw_text"),
        line_items_json,
        data.get("transaction_date") or now_iso,
        now_iso,
        None
    ))
    conn.commit()
    conn.close()
    return tx_id

def get_prepared_transactions(status: Optional[str] = None) -> List[dict]:
    conn = get_connection()
    cursor = conn.cursor()
    if status:
        cursor.execute("SELECT * FROM prepared_transactions WHERE status = ? ORDER BY created_at DESC", (status,))
    else:
        cursor.execute("SELECT * FROM prepared_transactions ORDER BY created_at DESC")
    rows = cursor.fetchall()
    
    results = []
    for row in rows:
        d = dict(row)
        try:
            d["line_items"] = json.loads(d.get("line_items_json") or "[]")
        except Exception:
            d["line_items"] = []
        d.pop("line_items_json", None)
        results.append(d)
        
    conn.close()
    return results

def get_prepared_transaction_by_id(tx_id: str) -> Optional[dict]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM prepared_transactions WHERE id = ?", (tx_id,))
    row = cursor.fetchone()
    conn.close()
    if not row:
        return None
    d = dict(row)
    try:
        d["line_items"] = json.loads(d.get("line_items_json") or "[]")
    except Exception:
        d["line_items"] = []
    d.pop("line_items_json", None)
    return d

def update_prepared_transaction_status(tx_id: str, status: str, overrides: Optional[dict] = None) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    now_iso = datetime.utcnow().isoformat()
    
    if overrides:
        category = overrides.get("override_category")
        amount = overrides.get("override_amount")
        cursor.execute("""
        UPDATE prepared_transactions
        SET status = ?,
            approved_at = ?,
            category = COALESCE(?, category),
            amount = COALESCE(?, amount)
        WHERE id = ?
        """, (status, now_iso if status == "approved" else None, category, amount, tx_id))
    else:
        cursor.execute("""
        UPDATE prepared_transactions
        SET status = ?,
            approved_at = ?
        WHERE id = ?
        """, (status, now_iso if status == "approved" else None, tx_id))
        
    updated = cursor.rowcount > 0
    conn.commit()
    conn.close()
    return updated

def approve_all_pending_transactions() -> int:
    conn = get_connection()
    cursor = conn.cursor()
    now_iso = datetime.utcnow().isoformat()
    cursor.execute("""
    UPDATE prepared_transactions
    SET status = 'approved', approved_at = ?
    WHERE status = 'pending_review'
    """, (now_iso,))
    count = cursor.rowcount
    conn.commit()
    conn.close()
    return count
