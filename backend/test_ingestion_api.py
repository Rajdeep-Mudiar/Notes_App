import os
import shutil
import uuid
from pathlib import Path
from bson import ObjectId
from fastapi.testclient import TestClient

from app.core.database import db_manager
from app.main import app


def test_document_ingestion_and_vector_search_e2e():
    print("\n" + "=" * 50)
    print("PHASE 10: DOCUMENT INGESTION & VECTOR EMBEDDINGS E2E TEST")
    print("=" * 50 + "\n")

    unique_id = str(uuid.uuid4())[:8]

    with TestClient(app) as client:
        # Step 1: Register student
        print("[Step 1] Registering student...")
        user_email = f"ai_student_{unique_id}@stanford.edu"
        reg_payload = {
            "email": user_email,
            "password": "SecurePassword123!",
            "full_name": "Geoffrey Hinton",
            "university": "Stanford University",
            "degree": "B.S. Artificial Intelligence",
            "current_semester": 5,
        }
        reg_resp = client.post("/api/v1/auth/register", json=reg_payload)
        assert reg_resp.status_code == 201, f"Registration failed: {reg_resp.text}"
        token = reg_resp.json()["data"]["tokens"]["access_token"]
        user_id = reg_resp.json()["data"]["user"]["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" Student registered (ID: {user_id})")

        # Step 2: Create Subject (CS229 - Machine Learning)
        print("\n[Step 2] Creating Subject CS229...")
        sub_resp = client.post(
            "/api/v1/subjects",
            json={
                "name": "Machine Learning",
                "code": f"CS229_{unique_id[:4]}",
                "professor": "Dr. Andrew Ng",
                "credits": 4,
                "color": "#4F46E5",
                "icon": "code",
                "semester": 5,
            },
            headers=headers,
        )
        assert sub_resp.status_code == 201, f"Subject create failed: {sub_resp.text}"
        subject_id = sub_resp.json()["data"]["id"]
        print(f" Subject created (ID: {subject_id})")

        # Step 3: Create Notion-Style Block Note (Gradient Descent & Optimization)
        print("\n[Step 3] Creating Block Note for CS229...")
        note_resp = client.post(
            "/api/v1/notes",
            json={
                "title": "Gradient Descent and Convex Optimization",
                "subject_id": subject_id,
                "blocks": [
                    {
                        "id": "b1",
                        "type": "heading_1",
                        "content": "Gradient Descent Optimization",
                        "order": 0,
                    },
                    {
                        "id": "b2",
                        "type": "paragraph",
                        "content": "Gradient descent is a first-order iterative optimization algorithm for finding a local minimum of a differentiable function. In machine learning, we update parameters theta by moving in the opposite direction of the gradient of the loss function with learning rate alpha.",
                        "order": 1,
                    },
                    {
                        "id": "b3",
                        "type": "code",
                        "content": "def gradient_descent(X, y, theta, alpha, iterations):\n    m = len(y)\n    for _ in range(iterations):\n        predictions = X.dot(theta)\n        theta = theta - (alpha / m) * X.T.dot(predictions - y)\n    return theta",
                        "order": 2,
                        "properties": {"language": "python"},
                    },
                    {
                        "id": "b4",
                        "type": "checklist",
                        "content": "Derive analytical gradient for MSE loss function",
                        "order": 3,
                        "properties": {"checked": True},
                    },
                ],
                "tags": ["optimization", "gradient-descent", "algorithms"],
                "is_pinned": True,
            },
            headers=headers,
        )
        assert note_resp.status_code == 201, f"Note create failed: {note_resp.text}"
        note_id = note_resp.json()["data"]["id"]
        print(f" Note created (ID: {note_id})")

        # Step 4: Ingest Note Blocks
        print("\n[Step 4] Ingesting Note into Vector Database...")
        ingest_note_resp = client.post(
            f"/api/v1/ingestion/notes/{note_id}/process",
            headers=headers,
        )
        assert ingest_note_resp.status_code == 200, f"Note ingestion failed: {ingest_note_resp.text}"
        note_status = ingest_note_resp.json()
        assert note_status["status"] == "completed"
        assert note_status["chunks_count"] >= 1
        assert note_status["total_tokens"] > 10
        print(f" Note successfully vectorized: {note_status['chunks_count']} chunk(s), {note_status['total_tokens']} tokens.")

        # Step 5: Check Ingestion Status Endpoint
        print("\n[Step 5] Checking GET /api/v1/ingestion/status/{note_id}...")
        status_check = client.get(f"/api/v1/ingestion/status/{note_id}", headers=headers)
        assert status_check.status_code == 200
        assert status_check.json()["status"] == "completed"
        print(" Ingestion status endpoint verified.")

        # Step 6: Create and Upload a File
        print("\n[Step 6] Creating and Uploading Lecture PDF/Text File...")
        file_content = (
            "Lecture 04: Deep Neural Networks and Backpropagation.\n\n"
            "Neural networks consist of multiple interconnected layers of artificial neurons. "
            "Forward propagation computes activations across hidden layers with non-linear activation functions like ReLU. "
            "Backpropagation computes the error gradient of the cost function with respect to weights using the chain rule of calculus."
        ).encode("utf-8")

        files = {
            "file": ("Lecture04_Backprop.txt", file_content, "text/plain")
        }
        upload_resp = client.post(
            "/api/v1/files/upload",
            files=files,
            data={"subject_id": subject_id},
            headers=headers,
        )
        assert upload_resp.status_code == 201, f"File upload failed: {upload_resp.text}"
        file_json = upload_resp.json()
        file_id = file_json.get("data", {}).get("id") if isinstance(file_json.get("data"), dict) else file_json.get("id")
        print(f" File uploaded (ID: {file_id})")

        # Step 7: Ingest Uploaded File
        print("\n[Step 7] Ingesting Uploaded File into Vector Store...")
        ingest_file_resp = client.post(
            f"/api/v1/ingestion/files/{file_id}/process",
            headers=headers,
        )
        assert ingest_file_resp.status_code == 200, f"File ingestion failed: {ingest_file_resp.text}"
        file_status = ingest_file_resp.json()
        assert file_status["status"] == "completed"
        assert file_status["chunks_count"] >= 1
        print(f" File successfully vectorized: {file_status['chunks_count']} chunk(s), {file_status['total_tokens']} tokens.")

        # Step 8: Perform Vector Semantic Search
        print("\n[Step 8] Performing Vector Semantic Search Queries...")
        # Query 1: Gradient descent search
        search_resp1 = client.post(
            "/api/v1/ingestion/query",
            json={
                "query": "iterative gradient descent optimization algorithm",
                "top_k": 3,
            },
            headers=headers,
        )
        assert search_resp1.status_code == 200
        data1 = search_resp1.json()
        assert data1["results_count"] > 0
        top_result1 = data1["results"][0]
        assert "Gradient" in top_result1["text_content"] or "gradient" in top_result1["text_content"].lower()
        print(f" Query 1 matched source '{top_result1['source_name']}' with similarity score {top_result1['similarity_score']:.4f}")

        # Query 2: Neural network backpropagation search
        search_resp2 = client.post(
            "/api/v1/ingestion/query",
            json={
                "query": "neural networks backpropagation chain rule",
                "top_k": 3,
                "source_type": "file",
            },
            headers=headers,
        )
        assert search_resp2.status_code == 200
        data2 = search_resp2.json()
        assert data2["results_count"] > 0
        top_result2 = data2["results"][0]
        assert "Backpropagation" in top_result2["text_content"] or "Neural" in top_result2["text_content"]
        print(f" Query 2 matched file source '{top_result2['source_name']}' with similarity score {top_result2['similarity_score']:.4f}")

        # Step 9: Ingestion Knowledge Stats
        print("\n[Step 9] Checking GET /api/v1/ingestion/stats...")
        stats_resp = client.get("/api/v1/ingestion/stats", headers=headers)
        assert stats_resp.status_code == 200
        stats = stats_resp.json()
        assert stats["total_chunks"] >= 2
        assert stats["total_indexed_files"] == 1
        assert stats["total_indexed_notes"] == 1
        assert stats["total_tokens_estimated"] > 0
        assert subject_id in stats["by_subject"]
        print(f" Stats verified: {stats['total_chunks']} chunks across {stats['total_indexed_files']} file(s) and {stats['total_indexed_notes']} note(s).")

        # Step 10: Delete Source Chunks
        print("\n[Step 10] Deleting Note index via DELETE /api/v1/ingestion/sources/{note_id}...")
        del_resp = client.delete(f"/api/v1/ingestion/sources/{note_id}", headers=headers)
        assert del_resp.status_code == 200
        assert del_resp.json()["deleted_count"] >= 1

        # Re-check stats
        updated_stats = client.get("/api/v1/ingestion/stats", headers=headers).json()
        assert updated_stats["total_indexed_notes"] == 0
        assert updated_stats["total_indexed_files"] == 1
        print(" Note chunks successfully purged.")

        # Step 11: Cleanup MongoDB and filesystem
        if db_manager.db is not None:
            db_manager.db["users"].delete_many({"email": user_email})
            db_manager.db["subjects"].delete_many({"user_id": ObjectId(user_id)})
            db_manager.db["notes"].delete_many({"user_id": user_id})
            db_manager.db["files"].delete_many({"user_id": ObjectId(user_id)})
            db_manager.db["document_chunks"].delete_many({"user_id": user_id})
            db_manager.db["ingestion_status"].delete_many({"user_id": user_id})

        user_upload_dir = Path(__file__).resolve().parent / "uploads" / user_id
        if user_upload_dir.exists():
            shutil.rmtree(user_upload_dir, ignore_errors=True)

        print("\n Cleaned up test data from MongoDB and filesystem.")

    print("=" * 50)
    print(" All Phase 10 Ingestion & Vector Embeddings API Tests PASSED!")
    print("=" * 50 + "\n")


if __name__ == "__main__":
    test_document_ingestion_and_vector_search_e2e()
