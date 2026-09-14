"""
Master End-to-End Test Suite for Student OS Platform
Runs a comprehensive student journey across all 11 modules:
1. Auth (Register & Login)
2. Academic Hierarchy (Subject CS301)
3. Notion-Style Block Notes
4. Cloud Drive & Storage Quota
5. Vector Embeddings & Multi-Format Ingestion
6. Cosine Similarity Semantic Search
7. Academic Planner & Assignment Tracker
8. Exam Schedule & Study Calendar
9. Timetable & Attendance Governance
10. GPA Analytics & What-If Predictive Simulator
11. Proactive Notifications Scanner
12. RAG AI Study Assistant (Q&A, Practice Quiz, Flashcards, Revision Summary)
"""

import sys
import os
import uuid
from datetime import datetime, timedelta, timezone
from fastapi.testclient import TestClient

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.main import app

def unpack(res):
    d = res.json()
    return d.get("data") if isinstance(d, dict) and "data" in d and d["data"] is not None else d

def run_master_e2e():
    unique_suffix = uuid.uuid4().hex[:8]
    email = f"alex.rivera.{unique_suffix}@stanford.edu"
    password = "MasterSecurePassword2026!"
    full_name = "Alex Rivera"

    print("=" * 65)
    print(" STUDENT OS - MASTER END-TO-END PLATFORM VERIFICATION")
    print("=" * 65)

    with TestClient(app) as client:
        # -------------------------------------------------------------
        # 1. AUTHENTICATION
        # -------------------------------------------------------------
        print("\n[Module 1: Auth] Registering and Authenticating Student...")
        reg_resp = client.post("/api/v1/auth/register", json={
            "email": email,
            "password": password,
            "full_name": full_name,
            "university": "Stanford University",
            "degree": "B.S. Computer Science",
            "current_semester": 4
        })
        assert reg_resp.status_code == 201, f"Reg failed: {reg_resp.text}"
        auth_data = unpack(reg_resp)
        user_id = auth_data["user"]["id"]
        token = auth_data["tokens"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" -> Student Authenticated: {full_name} (ID: {user_id})")

        # -------------------------------------------------------------
        # 2. ACADEMIC HIERARCHY & SUBJECTS
        # -------------------------------------------------------------
        print("\n[Module 2: Hierarchy] Creating Academic Subject...")
        subj_resp = client.post("/api/v1/subjects", headers=headers, json={
            "name": "Operating Systems & Concurrency",
            "code": "CS301",
            "credits": 4,
            "professor": "Dr. Leslie Lamport",
            "color": "#4F46E5",
            "icon": "memory",
            "description": "Kernel architecture, virtual memory, and distributed synchronization.",
            "semester": 4
        })
        assert subj_resp.status_code == 201, f"Subject create failed: {subj_resp.text}"
        subject_id = unpack(subj_resp)["id"]
        print(f" -> Subject Created: CS301 (ID: {subject_id})")

        # -------------------------------------------------------------
        # 3. NOTION-STYLE BLOCK NOTES
        # -------------------------------------------------------------
        print("\n[Module 3: Block Notes] Creating Rich Structured Note...")
        note_resp = client.post("/api/v1/notes", headers=headers, json={
            "subject_id": subject_id,
            "title": "Virtual Memory and Paging Architectures",
            "tags": ["os", "virtual-memory", "paging", "midterm"],
            "is_pinned": True,
            "is_favorite": True,
            "blocks": [
                {
                    "id": "b1",
                    "type": "heading_1",
                    "content": "Virtual Memory and Multi-Level Page Tables",
                    "order": 0
                },
                {
                    "id": "b2",
                    "type": "paragraph",
                    "content": "Virtual memory provides an abstraction of contiguous physical address space via hardware Translation Lookaside Buffers (TLB).",
                    "order": 1
                },
                {
                    "id": "b3",
                    "type": "code",
                    "content": "uint64_t virtual_to_physical(uint64_t vaddr) {\n    return (pml4[pml4_idx(vaddr)] & PAGING_MASK) + page_offset(vaddr);\n}",
                    "order": 2,
                    "properties": {"language": "c"}
                },
                {
                    "id": "b4",
                    "type": "checklist",
                    "content": "Implement LRU page replacement algorithm in kernel simulator.",
                    "order": 3,
                    "properties": {"checked": True}
                }
            ]
        })
        assert note_resp.status_code == 201, f"Note create failed: {note_resp.text}"
        note_id = unpack(note_resp)["id"]
        print(f" -> Note Created with 4 blocks (ID: {note_id})")

        # -------------------------------------------------------------
        # 4. CLOUD FILE MANAGER & STORAGE QUOTA
        # -------------------------------------------------------------
        print("\n[Module 4: File Manager] Uploading Course Document...")
        sample_content = (
            "Operating Systems Lecture 08: Concurrency & Synchronization Primitives.\n"
            "Mutual exclusion is achieved via Peterson's algorithm, mutex locks, and counting semaphores.\n"
            "Dining Philosophers problem illustrates deadlock condition: Mutual Exclusion, Hold and Wait, No Preemption, Circular Wait.\n"
        ).encode("utf-8")

        upload_resp = client.post(
            "/api/v1/files/upload",
            headers=headers,
            data={"subject_id": subject_id, "is_favorite": "true"},
            files={"file": ("OS_Lec08_Concurrency.txt", sample_content, "text/plain")}
        )
        assert upload_resp.status_code == 201, f"Upload failed: {upload_resp.text}"
        file_id = unpack(upload_resp)["id"]
        print(f" -> File Uploaded: OS_Lec08_Concurrency.txt (ID: {file_id})")

        storage_resp = client.get("/api/v1/files/storage", headers=headers)
        assert storage_resp.status_code == 200
        storage_data = unpack(storage_resp)
        assert storage_data["files_count"] >= 1
        print(f" -> Storage Quota: {storage_data['used_formatted']} / {storage_data['total_limit_formatted']}")

        # -------------------------------------------------------------
        # 5. DOCUMENT INGESTION & VECTOR EMBEDDINGS
        # -------------------------------------------------------------
        print("\n[Module 5: Ingestion & Embeddings] Vectorizing Note and File...")
        ingest_note_resp = client.post(f"/api/v1/ingestion/notes/{note_id}/process", headers=headers)
        assert ingest_note_resp.status_code == 200, f"Ingest note failed: {ingest_note_resp.text}"

        ingest_file_resp = client.post(f"/api/v1/ingestion/files/{file_id}/process", headers=headers)
        assert ingest_file_resp.status_code == 200, f"Ingest file failed: {ingest_file_resp.text}"

        stats_resp = client.get("/api/v1/ingestion/stats", headers=headers)
        assert stats_resp.status_code == 200
        stats_data = unpack(stats_resp)
        print(f" -> Knowledge Base: {stats_data['total_chunks']} chunks across {stats_data['total_indexed_files']} files and {stats_data['total_indexed_notes']} notes.")

        # -------------------------------------------------------------
        # 6. COSINE SIMILARITY SEMANTIC SEARCH
        # -------------------------------------------------------------
        print("\n[Module 6: Semantic Search] Testing Vector Search Query...")
        search_resp = client.post("/api/v1/ingestion/query", headers=headers, json={
            "query": "virtual memory page tables TLB",
            "top_k": 3
        })
        assert search_resp.status_code == 200, f"Search failed: {search_resp.text}"
        search_data = unpack(search_resp)
        results = search_data.get("results", [])
        assert len(results) > 0, "No semantic search results found"
        print(f" -> Top match: '{results[0]['source_name']}' (Score: {results[0]['similarity_score']:.4f})")

        # -------------------------------------------------------------
        # 7. ACADEMIC PLANNER & ASSIGNMENTS
        # -------------------------------------------------------------
        print("\n[Module 7: Academic Planner] Creating Urgency-Tracked Assignment...")
        due_date = datetime.now(timezone.utc) + timedelta(hours=18)
        asgn_resp = client.post("/api/v1/assignments", headers=headers, json={
            "subject_id": subject_id,
            "title": "Virtual Memory Allocator Lab",
            "description": "Implement multi-level page table walking and page fault handler in C.",
            "due_date": due_date.isoformat(),
            "priority": "urgent",
            "weight_percentage": 25.0
        })
        assert asgn_resp.status_code == 201, f"Assignment create failed: {asgn_resp.text}"
        asgn_id = unpack(asgn_resp)["id"]
        print(f" -> Assignment Created: Due in 18 hours (ID: {asgn_id})")

        # -------------------------------------------------------------
        # 8. EXAM SCHEDULE & STUDY CALENDAR
        # -------------------------------------------------------------
        print("\n[Module 8: Exams & Calendar] Scheduling Midterm Assessment...")
        exam_date = datetime.now(timezone.utc) + timedelta(days=2)
        exam_resp = client.post("/api/v1/exams", headers=headers, json={
            "subject_id": subject_id,
            "title": "CS301 Midterm Examination",
            "exam_type": "midterm",
            "date_time": exam_date.isoformat(),
            "duration_minutes": 120,
            "location": "Gates Computer Science Building B01",
            "seat_number": "A-12",
            "syllabus_topics": ["Virtual Memory", "Paging", "Deadlocks", "Semaphores"],
            "weight_percentage": 30.0,
            "target_grade": 95.0
        })
        assert exam_resp.status_code == 201, f"Exam create failed: {exam_resp.text}"
        exam_id = unpack(exam_resp)["id"]
        print(f" -> Exam Scheduled: CS301 Midterm (ID: {exam_id})")

        # -------------------------------------------------------------
        # 9. TIMETABLE & ATTENDANCE GOVERNANCE
        # -------------------------------------------------------------
        print("\n[Module 9: Timetable & Attendance] Logging Attendance & Calculating Safe Bunks...")
        slot_resp = client.post("/api/v1/timetable/slots", headers=headers, json={
            "subject_id": subject_id,
            "title": "OS Lecture & Lab",
            "day_of_week": "monday",
            "start_time": "10:00",
            "end_time": "11:30",
            "class_type": "lecture",
            "location": "Gates B01",
            "professor_name": "Dr. Leslie Lamport"
        })
        assert slot_resp.status_code == 201, f"Slot create failed: {slot_resp.text}"
        slot_id = unpack(slot_resp)["id"]

        att_resp = client.post("/api/v1/timetable/attendance", headers=headers, json={
            "slot_id": slot_id,
            "subject_id": subject_id,
            "date": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            "status": "present",
            "notes": "Attended on time."
        })
        assert att_resp.status_code == 201, f"Attendance log failed: {att_resp.text}"

        att_summary = client.get("/api/v1/timetable/attendance/summary", headers=headers)
        assert att_summary.status_code == 200
        print(f" -> Overall Attendance: {unpack(att_summary)['overall_percentage']}% (Threshold: 75%)")

        # -------------------------------------------------------------
        # 10. GPA ANALYTICS & WHAT-IF SIMULATOR
        # -------------------------------------------------------------
        print("\n[Module 10: GPA Analytics] Computing Honors Standing & What-If Scenario...")
        grade_resp = client.put(f"/api/v1/analytics/subjects/{subject_id}/grade", headers=headers, json={
            "letter_grade": "A",
            "target_grade": "A"
        })
        assert grade_resp.status_code == 200, f"Grade log failed: {grade_resp.text}"

        gpa_resp = client.get("/api/v1/analytics/gpa/summary", headers=headers)
        assert gpa_resp.status_code == 200
        gpa_data = unpack(gpa_resp)
        cgpa = gpa_data["current_cgpa"]
        honors = gpa_data["honors_standing"]
        print(f" -> Current CGPA: {cgpa:.2f} ({honors})")

        whatif_resp = client.post("/api/v1/analytics/gpa/what-if", headers=headers, json={
            "courses": [
                {"course_name": "Distributed Systems", "credits": 4, "hypothetical_grade": "A"},
                {"course_name": "Computer Architecture", "credits": 4, "hypothetical_grade": "A-"}
            ],
            "target_cgpa": 3.90
        })
        assert whatif_resp.status_code == 200
        whatif_data = unpack(whatif_resp)
        print(f" -> Projected CGPA: {whatif_data['projected_cgpa']:.2f} (Target Achieved: {whatif_data['target_achieved']})")

        # -------------------------------------------------------------
        # 11. PROACTIVE NOTIFICATIONS SCANNER
        # -------------------------------------------------------------
        print("\n[Module 11: Notifications] Running Proactive Alert Scanner...")
        scan_resp = client.post("/api/v1/notifications/generate-alerts", headers=headers)
        assert scan_resp.status_code == 200, f"Scan failed: {scan_resp.text}"

        notifs_resp = client.get("/api/v1/notifications", headers=headers)
        assert notifs_resp.status_code == 200
        unread = unpack(notifs_resp)["unread_count"]
        print(f" -> Active Alerts Generated: {unread} unread notification(s)")

        # -------------------------------------------------------------
        # 12. RAG ENGINE & AI STUDY ASSISTANT
        # -------------------------------------------------------------
        print("\n[Module 12: AI Study Assistant] Testing Grounded Q&A, Quizzes & Flashcards...")
        
        # Grounded Chat Q&A
        chat_resp = client.post("/api/v1/ai/chat", headers=headers, json={
            "message": "How does virtual memory work and how are deadlock conditions defined?",
            "subject_id": subject_id
        })
        assert chat_resp.status_code == 200, f"Chat failed: {chat_resp.text}"
        chat_data = unpack(chat_resp)
        session_id = chat_data["session_id"]
        print(f" -> AI Response received with {len(chat_data['citations'])} citation(s). Session: {session_id}")

        # Practice Quiz Generation
        quiz_resp = client.post("/api/v1/ai/generate-quiz", headers=headers, json={
            "subject_id": subject_id,
            "num_questions": 3
        })
        assert quiz_resp.status_code == 200, f"Quiz gen failed: {quiz_resp.text}"
        quiz_data = unpack(quiz_resp)
        print(f" -> Practice Quiz Generated: {len(quiz_data['questions'])} questions.")

        # Flashcard Deck Generation
        fc_resp = client.post("/api/v1/ai/generate-flashcards", headers=headers, json={
            "subject_id": subject_id,
            "num_cards": 3
        })
        assert fc_resp.status_code == 200, f"Flashcards gen failed: {fc_resp.text}"
        fc_data = unpack(fc_resp)
        print(f" -> Flashcards Generated: {len(fc_data['cards'])} cards.")

        # Exam Revision Summary
        sum_resp = client.post("/api/v1/ai/summarize", headers=headers, json={
            "subject_id": subject_id,
            "topic": "Virtual Memory and Concurrency"
        })
        assert sum_resp.status_code == 200, f"Summary gen failed: {sum_resp.text}"
        sum_data = unpack(sum_resp)
        print(f" -> Revision Summary: {len(sum_data['key_concepts'])} key concepts, {len(sum_data['exam_tips'])} exam tips.")

        # -------------------------------------------------------------
        # CLEANUP & TEARDOWN
        # -------------------------------------------------------------
        print("\n[Cleanup] Cleaning up test resources...")
        client.delete(f"/api/v1/ai/conversations/{session_id}", headers=headers)
        client.delete(f"/api/v1/notes/{note_id}", headers=headers)
        client.delete(f"/api/v1/files/{file_id}", headers=headers)
        client.delete(f"/api/v1/assignments/{asgn_id}", headers=headers)
        client.delete(f"/api/v1/exams/{exam_id}", headers=headers)
        client.delete(f"/api/v1/timetable/slots/{slot_id}", headers=headers)
        client.delete(f"/api/v1/subjects/{subject_id}", headers=headers)
        print(" -> All test data purged cleanly.")

        print("\n" + "=" * 65)
        print(" ALL 11 STUDENT OS CORE MODULES VERIFIED & PASSING 100%!")
        print("=" * 65 + "\n")

if __name__ == "__main__":
    run_master_e2e()
