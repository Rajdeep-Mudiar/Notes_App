import io
import uuid
from pathlib import Path
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_files_api_full_workflow():
    print("\n" + "=" * 50)
    print("PHASE 4: CLOUD FILE MANAGER FULL E2E TEST")
    print("=" * 50)

    test_email = f"filestudent_{uuid.uuid4().hex[:8]}@university.edu"
    test_password = "Password123!"

    with client:
        # 1. Register student
        print("\n[Step 1] Registering student...")
        student_payload = {
            "email": test_email,
            "password": test_password,
            "full_name": "Jordan Cloud",
            "university": "UC Berkeley",
            "degree": "B.S. EECS",
            "current_semester": 3,
        }
        reg_res = client.post("/api/v1/auth/register", json=student_payload)
        assert reg_res.status_code == 201, f"Reg failed: {reg_res.text}"
        user_data = reg_res.json()["data"]["user"]
        token = reg_res.json()["data"]["tokens"]["access_token"]
        user_id = user_data["id"]
        headers = {"Authorization": f"Bearer {token}"}
        print(f" Student registered (ID: {user_id})")

        try:
            # 2. Create Subject
            print("\n[Step 2] Creating Subject: CS61B Data Structures...")
            subj_res = client.post(
                "/api/v1/subjects",
                headers=headers,
                json={
                    "name": "Data Structures",
                    "code": "CS61B",
                    "professor": "Prof. Josh Hug",
                    "credits": 4,
                    "color": "#10B981",
                    "semester": 3,
                },
            )
            assert subj_res.status_code == 201
            subject_id = subj_res.json()["data"]["id"]
            print(f" Subject created (ID: {subject_id})")

            # 3. Create Folder
            print("\n[Step 3] Creating Folder: 'Lecture Slides' under Subject...")
            folder_res = client.post(
                "/api/v1/files/folders",
                headers=headers,
                json={
                    "name": "Lecture Slides",
                    "subject_id": subject_id,
                    "color": "#10B981",
                    "icon": "folder",
                },
            )
            assert folder_res.status_code == 201, f"Folder create failed: {folder_res.text}"
            folder_id = folder_res.json()["id"]
            print(f" Folder created: 'Lecture Slides' (ID: {folder_id})")

            # 4. Upload PDF File into Folder
            print("\n[Step 4] Uploading PDF: 'Lecture01_Intro.pdf' (Simulated binary)...")
            pdf_content = b"%PDF-1.4 Mock PDF Content For University Lecture 01 Data Structures"
            pdf_file = io.BytesIO(pdf_content)

            upload_res1 = client.post(
                "/api/v1/files/upload",
                headers=headers,
                files={"file": ("Lecture01_Intro.pdf", pdf_file, "application/pdf")},
                data={"subject_id": subject_id, "folder_id": folder_id},
            )
            assert upload_res1.status_code == 201, f"Upload 1 failed: {upload_res1.text}"
            file1 = upload_res1.json()
            file1_id = file1["id"]
            assert file1["file_type"] == "pdf"
            assert file1["original_name"] == "Lecture01_Intro.pdf"
            assert file1["size_bytes"] == len(pdf_content)
            print(f" Uploaded PDF: {file1['original_name']} ({file1['size_formatted']}, type: {file1['file_type']})")

            # 5. Upload Image File into Root
            print("\n[Step 5] Uploading Image: 'AVL_Tree_Diagram.png'...")
            img_content = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR Mock Image Binary Data"
            img_file = io.BytesIO(img_content)

            upload_res2 = client.post(
                "/api/v1/files/upload",
                headers=headers,
                files={"file": ("AVL_Tree_Diagram.png", img_file, "image/png")},
                data={"subject_id": subject_id},
            )
            assert upload_res2.status_code == 201, f"Upload 2 failed: {upload_res2.text}"
            file2 = upload_res2.json()
            file2_id = file2["id"]
            assert file2["file_type"] == "image"
            print(f" Uploaded Image: {file2['original_name']} ({file2['size_formatted']}, type: {file2['file_type']})")

            # 6. Verify Subject files_count Synchronization
            print("\n[Step 6] Verifying Subject files_count sync...")
            check_subj = client.get(f"/api/v1/subjects/{subject_id}", headers=headers)
            assert check_subj.status_code == 200
            assert check_subj.json()["data"]["files_count"] == 2
            print(" Subject files_count correctly synced to 2 files.")

            # 7. Check Storage Summary
            print("\n[Step 7] Checking Storage Summary metrics...")
            storage_res = client.get("/api/v1/files/storage", headers=headers)
            assert storage_res.status_code == 200
            storage = storage_res.json()
            assert storage["files_count"] == 2
            assert storage["used_bytes"] == len(pdf_content) + len(img_content)
            assert "pdf" in storage["by_type"]
            assert "image" in storage["by_type"]
            print(f" Storage summary: {storage['used_formatted']} / {storage['total_limit_formatted']} ({storage['percentage_used']}%)")

            # 8. Test File Download
            print("\n[Step 8] Downloading PDF file from /download endpoint...")
            download_res = client.get(f"/api/v1/files/{file1_id}/download", headers=headers)
            assert download_res.status_code == 200
            assert download_res.content == pdf_content
            print(f" Downloaded {len(download_res.content)} bytes, matched exact binary content!")

            # 9. Toggle Favorite on File
            print("\n[Step 9] Toggling favorite status on image file...")
            fav_res = client.patch(f"/api/v1/files/{file2_id}/favorite", headers=headers)
            assert fav_res.status_code == 200
            assert fav_res.json()["is_favorite"] is True
            print(" Favorite star toggled successfully.")

            # 10. List Files filtered by Subject & FileType
            print("\n[Step 10] Listing PDF files for subject...")
            list_res = client.get(
                f"/api/v1/files?subject_id={subject_id}&file_type=pdf",
                headers=headers,
            )
            assert list_res.status_code == 200
            items = list_res.json()["items"]
            assert len(items) == 1
            assert items[0]["original_name"] == "Lecture01_Intro.pdf"
            print(f" Filtered list returned {len(items)} PDF item(s).")

            # 11. Delete File 2 & Verify files_count Decrements
            print("\n[Step 11] Deleting Image file...")
            del_res = client.delete(f"/api/v1/files/{file2_id}", headers=headers)
            assert del_res.status_code == 200
            check_subj2 = client.get(f"/api/v1/subjects/{subject_id}", headers=headers)
            assert check_subj2.json()["data"]["files_count"] == 1
            print(" File deleted and subject files_count decremented to 1.")

            # 12. Delete Folder
            print("\n[Step 12] Deleting folder...")
            del_folder = client.delete(f"/api/v1/files/folders/{folder_id}", headers=headers)
            assert del_folder.status_code == 200
            print(" Folder deleted.")

            # 13. Cleanup remaining file
            client.delete(f"/api/v1/files/{file1_id}", headers=headers)

        finally:
            # Cleanup test user from MongoDB
            import pymongo
            from bson import ObjectId
            from app.core.config import settings

            sync_client = pymongo.MongoClient(settings.MONGODB_URL)
            sync_db = sync_client[settings.DATABASE_NAME]
            sync_db["users"].delete_one({"_id": ObjectId(user_id)})
            sync_db["subjects"].delete_many({"user_id": ObjectId(user_id)})
            sync_db["notes"].delete_many({"user_id": ObjectId(user_id)})
            sync_db["files"].delete_many({"user_id": ObjectId(user_id)})
            sync_db["folders"].delete_many({"user_id": ObjectId(user_id)})
            sync_client.close()

            # Cleanup user disk folder
            upload_dir = Path(__file__).resolve().parent / "uploads" / str(user_id)
            if upload_dir.exists():
                import shutil
                shutil.rmtree(upload_dir, ignore_errors=True)

            print("\n Cleaned up test data from MongoDB & disk.")

    print("\n All Phase 4 Backend Cloud File Manager Tests PASSED!")
    print("=" * 50)


if __name__ == "__main__":
    test_files_api_full_workflow()
