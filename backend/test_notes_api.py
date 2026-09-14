import uuid
from fastapi.testclient import TestClient
import pymongo
from app.main import app
from app.core.config import settings

client = TestClient(app)


def test_notes_e2e_flow():
    print("==================================================")
    print("PHASE 3: NOTION-STYLE BLOCK NOTES SYSTEM E2E TEST")
    print("==================================================")

    test_email = f"notes_student_{uuid.uuid4().hex[:6]}@university.edu"
    test_password = "Password123!"

    with client:
        # 1. Register student
        print("\n[Step 1] Registering student...")
        reg_res = client.post("/api/v1/auth/register", json={
            "email": test_email,
            "password": test_password,
            "full_name": "Elena Rostova",
            "university": "MIT",
            "degree": "B.S. Computer Science",
            "current_semester": 4
        })
        assert reg_res.status_code == 201
        token = reg_res.json()["data"]["tokens"]["access_token"]
        user_id = reg_res.json()["data"]["user"]["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" Student registered (ID: {user_id})")

        # 2. Create Subject: Data Structures
        print("\n[Step 2] Creating Subject: Data Structures...")
        sub_res = client.post("/api/v1/subjects", headers=headers, json={
            "name": "Data Structures",
            "code": "CS204",
            "credits": 4,
            "color": "#4F46E5",
            "icon": "code",
            "semester": 4
        })
        assert sub_res.status_code == 201
        subject_id = sub_res.json()["data"]["id"]
        print(f" Subject created (ID: {subject_id})")

        # 3. Create Multi-Block Structured Note
        print("\n[Step 3] Creating Notion-Style Structured Note with 7 blocks...")
        blocks_payload = [
            {
                "id": "b1",
                "type": "heading_1",
                "content": "Binary Search Trees (BST)",
                "properties": {},
                "order": 0
            },
            {
                "id": "b2",
                "type": "paragraph",
                "content": "A BST is a node-based binary tree data structure with key ordering.",
                "properties": {},
                "order": 1
            },
            {
                "id": "b3",
                "type": "code",
                "content": "def insert(root, key):\n    if root is None:\n        return Node(key)\n    return root",
                "properties": {"language": "python"},
                "order": 2
            },
            {
                "id": "b4",
                "type": "checklist",
                "content": "Implement AVL Tree Self-Balancing rotations",
                "properties": {"checked": True},
                "order": 3
            },
            {
                "id": "b5",
                "type": "callout",
                "content": "Average search, insert and delete time complexity is O(log n).",
                "properties": {"type": "info", "icon": "info"},
                "order": 4
            },
            {
                "id": "b6",
                "type": "equation",
                "content": "T(n) = 2T(n/2) + O(1)",
                "properties": {},
                "order": 5
            },
            {
                "id": "b7",
                "type": "quote",
                "content": "Premature optimization is the root of all evil. - Donald Knuth",
                "properties": {},
                "order": 6
            }
        ]

        note_create_res = client.post("/api/v1/notes", headers=headers, json={
            "title": "BST & AVL Trees Master Notes",
            "subject_id": subject_id,
            "tags": ["dsa", "trees", "algorithms"],
            "icon": "article",
            "blocks": blocks_payload,
            "is_favorite": True,
            "is_pinned": True
        })
        assert note_create_res.status_code == 201, f"Error: {note_create_res.text}"
        note_data = note_create_res.json()["data"]
        note_id = note_data["id"]
        assert len(note_data["blocks"]) == 7
        assert note_data["subject_code"] == "CS204"
        print(f" Note created with 7 blocks: '{note_data['title']}' (ID: {note_id})")

        # 4. Check Subject notes_count updated to 1
        print("\n[Step 4] Verifying Subject notes_count synchronization...")
        sub_check = client.get(f"/api/v1/subjects/{subject_id}", headers=headers)
        assert sub_check.status_code == 200
        assert sub_check.json()["data"]["notes_count"] == 1
        print(" Subject notes_count accurately reflects 1 note.")

        # 5. List Notes with search & tag filter
        print("\n[Step 5] Listing notes filtered by tag 'trees' and keyword 'BST'...")
        list_res = client.get(f"/api/v1/notes?subject_id={subject_id}&tag=trees&search=BST", headers=headers)
        assert list_res.status_code == 200
        notes_list = list_res.json()["data"]["notes"]
        assert len(notes_list) == 1
        assert notes_list[0]["title"] == "BST & AVL Trees Master Notes"
        print(" Filtered notes list verified.")

        # 6. Retrieve Note by ID
        print("\n[Step 6] Fetching single note with full blocks...")
        get_res = client.get(f"/api/v1/notes/{note_id}", headers=headers)
        assert get_res.status_code == 200
        fetched_note = get_res.json()["data"]
        assert fetched_note["blocks"][2]["type"] == "code"
        assert fetched_note["blocks"][2]["properties"]["language"] == "python"
        assert fetched_note["blocks"][3]["type"] == "checklist"
        assert fetched_note["blocks"][3]["properties"]["checked"] is True
        print(" Block schema and properties verified with high precision.")

        # 7. Update Note (edit block & title)
        print("\n[Step 7] Updating note title and modifying blocks...")
        upd_res = client.put(f"/api/v1/notes/{note_id}", headers=headers, json={
            "title": "BST & AVL Trees Master Notes (Updated)",
            "blocks": blocks_payload[:3]  # keep first 3 blocks
        })
        assert upd_res.status_code == 200
        assert upd_res.json()["data"]["title"] == "BST & AVL Trees Master Notes (Updated)"
        assert len(upd_res.json()["data"]["blocks"]) == 3
        print(" Note updated successfully.")

        # 8. Toggle Favorite & Pin
        print("\n[Step 8] Testing Favorite and Pin toggles...")
        fav_res = client.patch(f"/api/v1/notes/{note_id}/favorite", headers=headers)
        assert fav_res.status_code == 200
        assert fav_res.json()["data"]["is_favorite"] is False
        pin_res = client.patch(f"/api/v1/notes/{note_id}/pin", headers=headers)
        assert pin_res.status_code == 200
        assert pin_res.json()["data"]["is_pinned"] is False
        print(" Toggles verified.")

        # 9. Test Recent Notes Endpoint
        print("\n[Step 9] Testing GET /api/v1/notes/recent for Dashboard...")
        rec_res = client.get("/api/v1/notes/recent?limit=5", headers=headers)
        assert rec_res.status_code == 200
        assert len(rec_res.json()["data"]) >= 1
        print(f" Retrieved {len(rec_res.json()['data'])} recent note(s).")

        # 10. Delete Note
        print("\n[Step 10] Deleting note...")
        del_res = client.delete(f"/api/v1/notes/{note_id}", headers=headers)
        assert del_res.status_code == 200
        print(" Note deleted.")

        # 11. Verify subject notes_count decremented to 0
        sub_check2 = client.get(f"/api/v1/subjects/{subject_id}", headers=headers)
        assert sub_check2.json()["data"]["notes_count"] == 0
        print(" Subject notes_count correctly updated back to 0.")

    # Cleanup Database
    sync_client = pymongo.MongoClient(settings.MONGODB_URL)
    sync_db = sync_client[settings.DATABASE_NAME]
    sync_db["users"].delete_one({"email": test_email})
    sync_db["subjects"].delete_many({"user_id": user_id})
    sync_db["notes"].delete_many({"user_id": user_id})
    sync_client.close()
    print("\n Cleaned up test data from MongoDB.")

    print("\n All Phase 3 Backend Notes API Tests PASSED!")
    print("==================================================")


if __name__ == "__main__":
    test_notes_e2e_flow()
