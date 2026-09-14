from typing import Any, Dict
from bson import ObjectId


def user_helper(doc: Dict[str, Any]) -> Dict[str, Any]:
    """Helper to convert MongoDB document to serializable dict."""
    if not doc:
        return {}
    res = dict(doc)
    if "_id" in res:
        res["id"] = str(res.pop("_id"))
    return res


def to_object_id(id_str: str) -> ObjectId:
    """Safely convert string to ObjectId."""
    try:
        return ObjectId(id_str)
    except Exception:
        raise ValueError(f"Invalid ObjectId: {id_str}")
