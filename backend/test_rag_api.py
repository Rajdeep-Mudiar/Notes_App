import os
import shutil
import uuid
from pathlib import Path
from bson import ObjectId
from fastapi.testclient import TestClient

from app.core.database import db_manager
from app.main import app


def test_rag_and_ai_assistant_e2e():
    print("\n" + "=" * 50)
    print("PHASE 11: RAG ENGINE & AI STUDY ASSISTANT E2E TEST")
    print("=" * 50 + "\n")

    unique_id = str(uuid.uuid4())[:8]

    with TestClient(app) as client:
        # Step 1: Register Student
        print("[Step 1] Registering student...")
        user_email = f"rag_student_{unique_id}@stanford.edu"
        reg_payload = {
            "email": user_email,
            "password": "SecurePassword123!",
            "full_name": "Yann LeCun",
            "university": "Stanford University",
            "degree": "Ph.D. Computer Science",
            "current_semester": 6,
        }
        reg_resp = client.post("/api/v1/auth/register", json=reg_payload)
        assert reg_resp.status_code == 201, f"Registration failed: {reg_resp.text}"
        token = reg_resp.json()["data"]["tokens"]["access_token"]
        user_id = reg_resp.json()["data"]["user"]["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" Student registered (ID: {user_id})")

        # Step 2: Create Subject (CS231N - Deep Learning)
        print("\n[Step 2] Creating Subject CS231N...")
        sub_resp = client.post(
            "/api/v1/subjects",
            json={
                "name": "Deep Learning for Computer Vision",
                "code": f"CS231N_{unique_id[:4]}",
                "professor": "Dr. Fei-Fei Li",
                "credits": 4,
                "color": "#6366F1",
                "icon": "visibility",
                "semester": 6,
            },
            headers=headers,
        )
        assert sub_resp.status_code == 201
        subject_id = sub_resp.json()["data"]["id"]
        print(f" Subject created (ID: {subject_id})")

        # Step 3: Create Structured Course Note on CNNs
        print("\n[Step 3] Creating Block Note on Convolutional Neural Networks...")
        note_resp = client.post(
            "/api/v1/notes",
            json={
                "title": "Convolutional Neural Networks and Feature Maps",
                "subject_id": subject_id,
                "blocks": [
                    {
                        "id": "b1",
                        "type": "heading_1",
                        "content": "Convolutional Layer Architecture",
                        "order": 0,
                    },
                    {
                        "id": "b2",
                        "type": "paragraph",
                        "content": "A Convolutional Layer applies learnable spatial filters across input tensor channels. "
                                   "The receptive field scans local receptive patches producing 2D activation feature maps. "
                                   "Stride controls filter step size while zero-padding preserves spatial dimensions.",
                        "order": 1,
                    },
                    {
                        "id": "b3",
                        "type": "code",
                        "content": "import torch.nn as nn\nconv_layer = nn.Conv2d(in_channels=3, out_channels=64, kernel_size=3, stride=1, padding=1)",
                        "order": 2,
                        "properties": {"language": "python"},
                    },
                    {
                        "id": "b4",
                        "type": "callout",
                        "content": "Pooling layers downsample spatial dimensions to achieve translation invariance.",
                        "order": 3,
                        "properties": {"icon": "💡"},
                    },
                ],
                "tags": ["cnn", "deep-learning", "vision"],
                "is_pinned": True,
            },
            headers=headers,
        )
        assert note_resp.status_code == 201
        note_id = note_resp.json()["data"]["id"]

        # Step 4: Index Note into Vector Store
        print("\n[Step 4] Vectorizing Note via Ingestion Pipeline...")
        ingest_note = client.post(f"/api/v1/ingestion/notes/{note_id}/process", headers=headers)
        assert ingest_note.status_code == 200
        assert ingest_note.json()["status"] == "completed"
        print(" Note vectorized and indexed.")

        # Step 5: Upload and Index Lecture Slides File
        print("\n[Step 5] Uploading and Vectorizing Lecture Notes File...")
        file_payload = (
            "Lecture 05: Backpropagation, Loss Functions, and Cross-Entropy.\n\n"
            "Softmax cross-entropy loss measures divergence between predicted class probabilities and one-hot true labels. "
            "The analytical gradient with respect to logits simplifies to: grad_z = probabilities - true_labels. "
            "Stochastic Gradient Descent (SGD) with momentum accelerates convergence across flat ravines."
        ).encode("utf-8")

        upload_resp = client.post(
            "/api/v1/files/upload",
            files={"file": ("Lecture05_Loss_Backprop.txt", file_payload, "text/plain")},
            data={"subject_id": subject_id},
            headers=headers,
        )
        assert upload_resp.status_code == 201
        file_json = upload_resp.json()
        file_id = file_json.get("data", {}).get("id") if isinstance(file_json.get("data"), dict) else file_json.get("id")

        ingest_file = client.post(f"/api/v1/ingestion/files/{file_id}/process", headers=headers)
        assert ingest_file.status_code == 200
        assert ingest_file.json()["status"] == "completed"
        print(f" File vectorized (ID: {file_id})")

        # Step 6: Grounded Conversational Q&A with Citations
        print("\n[Step 6] Testing Grounded Chat Q&A (POST /api/v1/ai/chat)...")
        chat_resp1 = client.post(
            "/api/v1/ai/chat",
            json={
                "message": "What is the role of convolutional layers and spatial filters in CNNs?",
                "subject_id": subject_id,
            },
            headers=headers,
        )
        assert chat_resp1.status_code == 200, f"Chat failed: {chat_resp1.text}"
        chat_data1 = chat_resp1.json()
        assert "reply" in chat_data1
        assert len(chat_data1["citations"]) > 0
        session_id = chat_data1["session_id"]
        print(f" Chat response received with {len(chat_data1['citations'])} citation(s). Session ID: {session_id}")
        print(f" Citation 1: '{chat_data1['citations'][0]['source_name']}'")

        # Step 7: Multi-turn Chat using existing session_id
        print("\n[Step 7] Testing Multi-turn conversation continuation...")
        chat_resp2 = client.post(
            "/api/v1/ai/chat",
            json={
                "message": "How does cross-entropy loss gradient simplify with softmax logits?",
                "subject_id": subject_id,
                "session_id": session_id,
            },
            headers=headers,
        )
        assert chat_resp2.status_code == 200
        chat_data2 = chat_resp2.json()
        assert chat_data2["session_id"] == session_id
        assert len(chat_data2["citations"]) > 0
        print(" Multi-turn turn completed successfully.")

        # Step 8: Auto-generate Practice Quiz
        print("\n[Step 8] Testing Practice Quiz Generator (POST /api/v1/ai/generate-quiz)...")
        quiz_resp = client.post(
            "/api/v1/ai/generate-quiz",
            json={
                "subject_id": subject_id,
                "num_questions": 3,
                "topic": "Convolutional Neural Networks and Softmax Loss",
            },
            headers=headers,
        )
        assert quiz_resp.status_code == 200, f"Quiz gen failed: {quiz_resp.text}"
        quiz_data = quiz_resp.json()
        assert quiz_data["total_questions"] >= 1
        first_q = quiz_data["questions"][0]
        assert len(first_q["options"]) == 4
        assert 0 <= first_q["correct_option_index"] < 4
        assert len(first_q["explanation"]) > 10
        print(f" Practice Quiz generated: {quiz_data['total_questions']} question(s).")
        print(f" Sample Question: \"{first_q['question']}\"")

        # Step 9: Auto-generate Flashcard Deck
        print("\n[Step 9] Testing Flashcard Deck Generator (POST /api/v1/ai/generate-flashcards)...")
        fc_resp = client.post(
            "/api/v1/ai/generate-flashcards",
            json={
                "subject_id": subject_id,
                "num_cards": 4,
                "topic": "CNN Architecture and Loss Gradients",
            },
            headers=headers,
        )
        assert fc_resp.status_code == 200, f"Flashcard gen failed: {fc_resp.text}"
        fc_data = fc_resp.json()
        assert fc_data["total_cards"] >= 1
        first_card = fc_data["cards"][0]
        assert len(first_card["front"]) > 0
        assert len(first_card["back"]) > 0
        print(f" Flashcards generated: {fc_data['total_cards']} card(s).")
        print(f" Front: \"{first_card['front']}\" | Back: \"{first_card['back'][:60]}...\"")

        # Step 10: Auto-generate Exam Revision Summary
        print("\n[Step 10] Testing Exam Revision Summarizer (POST /api/v1/ai/summarize)...")
        summary_resp = client.post(
            "/api/v1/ai/summarize",
            json={
                "subject_id": subject_id,
                "topic": "Midterm Exam High-Yield Review",
            },
            headers=headers,
        )
        assert summary_resp.status_code == 200, f"Summary gen failed: {summary_resp.text}"
        summary_data = summary_resp.json()
        assert len(summary_data["overview"]) > 20
        assert len(summary_data["key_concepts"]) > 0
        assert len(summary_data["exam_tips"]) > 0
        assert len(summary_data["citations"]) > 0
        print(f" Revision summary generated with {len(summary_data['key_concepts'])} key concepts and {len(summary_data['exam_tips'])} exam tips.")

        # Step 11: List and Retrieve Past Conversations
        print("\n[Step 11] Checking Conversations History Endpoints...")
        conv_list_resp = client.get("/api/v1/ai/conversations", headers=headers)
        assert conv_list_resp.status_code == 200
        conv_list = conv_list_resp.json()
        assert conv_list["total"] >= 1
        assert conv_list["sessions"][0]["id"] == session_id

        conv_detail = client.get(f"/api/v1/ai/conversations/{session_id}", headers=headers)
        assert conv_detail.status_code == 200
        assert len(conv_detail.json()["messages"]) >= 4  # 2 turns = 4 messages
        print(f" Session history verified ({len(conv_detail.json()['messages'])} messages).")

        # Step 12: Delete Session
        print("\n[Step 12] Deleting Study Session (DELETE /api/v1/ai/conversations/{session_id})...")
        del_conv_resp = client.delete(f"/api/v1/ai/conversations/{session_id}", headers=headers)
        assert del_conv_resp.status_code == 200
        print(" Conversation session deleted.")

        # Cleanup test data from MongoDB and disk
        if db_manager.db is not None:
            db_manager.db["users"].delete_many({"email": user_email})
            db_manager.db["subjects"].delete_many({"user_id": ObjectId(user_id)})
            db_manager.db["notes"].delete_many({"user_id": user_id})
            db_manager.db["files"].delete_many({"user_id": ObjectId(user_id)})
            db_manager.db["document_chunks"].delete_many({"user_id": user_id})
            db_manager.db["ingestion_status"].delete_many({"user_id": user_id})
            db_manager.db["ai_conversations"].delete_many({"user_id": user_id})

        user_upload_dir = Path(__file__).resolve().parent / "uploads" / user_id
        if user_upload_dir.exists():
            shutil.rmtree(user_upload_dir, ignore_errors=True)

        print("\n Cleaned up test data from MongoDB and filesystem.")

    print("=" * 50)
    print(" All Phase 11 RAG & AI Study Assistant API Tests PASSED!")
    print("=" * 50 + "\n")


if __name__ == "__main__":
    test_rag_and_ai_assistant_e2e()
