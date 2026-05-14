"""
GeekBrain AI — Bedrock Agent Action Group Lambda
Handles tool execution:
  - Database queries → RDS MySQL
"""

import json
import os
import pymysql

# RDS MySQL Configuration
DB_HOST = os.environ.get("DB_HOST", "")
DB_NAME = os.environ.get("DB_NAME", "")
DB_USER = os.environ.get("DB_USER", "")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")

# ═══════════════════════════════════════
# Tool Functions
# ═══════════════════════════════════════

def query_database(sql_query):
    """Execute a SELECT query on the GeekBrain RDS MySQL database."""
    try:
        if not sql_query.strip().upper().startswith("SELECT"):
            return {"error": "Only SELECT queries are allowed."}

        conn = pymysql.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            cursorclass=pymysql.cursors.DictCursor
        )
        with conn.cursor() as cursor:
            cursor.execute(sql_query)
            rows = cursor.fetchall()
            columns = list(rows[0].keys()) if rows else []
        conn.close()
        return {"columns": columns, "rows": rows, "row_count": len(rows)}
    except Exception as e:
        return {"error": str(e)}

# ═══════════════════════════════════════
# Bedrock Agent Action Group Handler
# ═══════════════════════════════════════

def handler(event, context):
    """Bedrock Agent Action Group Lambda handler."""
    print(f"Action Group Event: {json.dumps(event)}")

    function_name = event.get("function", "")
    parameters = {p["name"]: p["value"] for p in event.get("parameters", [])}

    # Dispatch to the correct tool function
    if function_name == "query_database":
        result = query_database(parameters.get("sql_query", ""))
    else:
        result = {"error": f"Unknown function: {function_name}"}

    return {
        "messageVersion": "1.0",
        "response": {
            "actionGroup": event.get("actionGroup", ""),
            "function": function_name,
            "functionResponse": {
                "responseBody": {
                    "TEXT": {"body": json.dumps(result, default=str)}
                }
            }
        }
    }
