import logging
from datetime import datetime, timezone, timedelta
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from app.core.security import hash_password

logger = logging.getLogger(__name__)


async def seed_initial_data(db: AsyncIOMotorDatabase) -> None:
    """Auto-seed sample student account and starter university workspace data if absent."""
    try:
        users_col = db["users"]
        sample_email = "alex.rivera@stanford.edu"
        existing_user = await users_col.find_one({"email": sample_email})

        now = datetime.now(timezone.utc)

        if not existing_user:
            logger.info("Seeding initial sample student account (alex.rivera@stanford.edu)...")
            user_doc = {
                "email": sample_email,
                "hashed_password": hash_password("Student123!"),
                "full_name": "Alex Rivera",
                "university": "Stanford University",
                "degree": "B.S. Computer Science",
                "current_semester": 4,
                "avatar_url": None,
                "is_active": True,
                "created_at": now,
                "updated_at": now,
            }
            result = await users_col.insert_one(user_doc)
            user_id = str(result.inserted_id)

            # 1. Starter Subjects
            subjects_col = db["subjects"]
            sub_cs106b = {
                "user_id": user_id,
                "name": "Programming Abstractions",
                "code": "CS 106B",
                "color": "#4F46E5",
                "credits": 4.0,
                "semester": 4,
                "description": "Data structures, recursion, memory management, and C++ algorithmic problem solving.",
                "target_attendance_percentage": 85.0,
                "is_archived": False,
                "created_at": now,
                "updated_at": now,
            }
            res_sub1 = await subjects_col.insert_one(sub_cs106b)
            cs106b_id = str(res_sub1.inserted_id)

            sub_cs107 = {
                "user_id": user_id,
                "name": "Computer Organization & Systems",
                "code": "CS 107",
                "color": "#06B6D4",
                "credits": 4.0,
                "semester": 4,
                "description": "C programming, x86-64 assembly, memory hierarchy, heap allocators, and hardware interaction.",
                "target_attendance_percentage": 80.0,
                "is_archived": False,
                "created_at": now,
                "updated_at": now,
            }
            res_sub2 = await subjects_col.insert_one(sub_cs107)
            cs107_id = str(res_sub2.inserted_id)

            sub_math51 = {
                "user_id": user_id,
                "name": "Linear Algebra & Multivariable Calculus",
                "code": "MATH 51",
                "color": "#10B981",
                "credits": 5.0,
                "semester": 4,
                "description": "Vector spaces, linear transformations, eigenvalues, multivariable gradients and optimization.",
                "target_attendance_percentage": 75.0,
                "is_archived": False,
                "created_at": now,
                "updated_at": now,
            }
            res_sub3 = await subjects_col.insert_one(sub_math51)
            math51_id = str(res_sub3.inserted_id)

            # 2. Starter Notes
            notes_col = db["notes"]
            await notes_col.insert_many([
                {
                    "user_id": user_id,
                    "subject_id": cs106b_id,
                    "title": "Binary Trees & BST Traversals",
                    "blocks": [
                        {"id": "b1", "type": "heading1", "content": "Binary Search Trees (BST)", "properties": {}},
                        {"id": "b2", "type": "paragraph", "content": "A BST is a rooted binary tree where each node key is greater than all keys in its left subtree and smaller than all keys in its right subtree.", "properties": {}},
                        {"id": "b3", "type": "code", "content": "struct TreeNode {\n    int val;\n    TreeNode* left;\n    TreeNode* right;\n    TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}\n};", "properties": {"language": "cpp"}},
                        {"id": "b4", "type": "bullet_list", "content": "In-order traversal yields sorted elements in O(N) time.", "properties": {}},
                        {"id": "b5", "type": "bullet_list", "content": "Search/Insert/Delete runs in O(log N) average, O(N) worst-case.", "properties": {}},
                    ],
                    "tags": ["data-structures", "trees", "exam-prep"],
                    "is_favorite": True,
                    "is_pinned": True,
                    "created_at": now,
                    "updated_at": now,
                },
                {
                    "user_id": user_id,
                    "subject_id": cs107,
                    "title": "Dynamic Memory Allocation & Heap Mechanics",
                    "blocks": [
                        {"id": "n1", "type": "heading1", "content": "Heap Allocation in C", "properties": {}},
                        {"id": "n2", "type": "paragraph", "content": "Memory is dynamically requested with malloc/calloc and returned with free. Implicit and explicit free lists track free blocks.", "properties": {}},
                        {"id": "n3", "type": "callout", "content": "Always ensure 8-byte or 16-byte alignment when managing heap headers and payload boundaries.", "properties": {}},
                    ],
                    "tags": ["c-programming", "memory", "pointers"],
                    "is_favorite": True,
                    "is_pinned": False,
                    "created_at": now,
                    "updated_at": now,
                }
            ])

            # 3. Starter Assignments
            assignments_col = db["assignments"]
            await assignments_col.insert_many([
                {
                    "user_id": user_id,
                    "subject_id": cs106b_id,
                    "title": "Programming Assignment 3: Huffman Coding",
                    "description": "Implement entropy compression using priority queues and binary tree reconstruction.",
                    "due_date": now + timedelta(days=3),
                    "status": "in_progress",
                    "priority": "high",
                    "estimated_hours": 8.0,
                    "tags": ["algorithms", "c++"],
                    "created_at": now,
                    "updated_at": now,
                },
                {
                    "user_id": user_id,
                    "subject_id": cs107_id,
                    "title": "Lab 2: Heap Allocator Implementation",
                    "description": "Design a fast implicit free-list memory allocator with coalescing.",
                    "due_date": now + timedelta(days=7),
                    "status": "todo",
                    "priority": "urgent",
                    "estimated_hours": 12.0,
                    "tags": ["systems", "c"],
                    "created_at": now,
                    "updated_at": now,
                },
                {
                    "user_id": user_id,
                    "subject_id": math51_id,
                    "title": "Problem Set 4: Eigenvalues & Principal Components",
                    "description": "Matrix diagonalizations and geometric transformations.",
                    "due_date": now + timedelta(days=1),
                    "status": "todo",
                    "priority": "medium",
                    "estimated_hours": 4.0,
                    "tags": ["math", "linear-algebra"],
                    "created_at": now,
                    "updated_at": now,
                }
            ])

            # 4. Starter Exams
            exams_col = db["exams"]
            await exams_col.insert_many([
                {
                    "user_id": user_id,
                    "subject_id": cs106b_id,
                    "title": "CS106B Midterm Examination",
                    "exam_type": "midterm",
                    "date_time": now + timedelta(days=5, hours=2),
                    "duration_minutes": 120,
                    "room_location": "Hewlett Hall 200",
                    "syllabus_topics": ["Recursion", "Backtracking", "Big-O", "Linked Lists", "Binary Trees"],
                    "weightage_percentage": 25.0,
                    "notes_description": "Closed-book exam. 1 sheet of handwritten notes allowed.",
                    "created_at": now,
                    "updated_at": now,
                },
                {
                    "user_id": user_id,
                    "subject_id": math51_id,
                    "title": "MATH 51 Final Exam",
                    "exam_type": "final",
                    "date_time": now + timedelta(days=21),
                    "duration_minutes": 180,
                    "room_location": "Turing Auditorium 101",
                    "syllabus_topics": ["Vector Spaces", "Subspaces", "Eigenvalues", "Optimization"],
                    "weightage_percentage": 40.0,
                    "notes_description": "Comprehensive final examination covering entire syllabus.",
                    "created_at": now,
                    "updated_at": now,
                }
            ])

            # 5. Starter Timetable Slots
            timetable_col = db["timetable_slots"]
            await timetable_col.insert_many([
                {
                    "user_id": user_id,
                    "subject_id": cs106b_id,
                    "day_of_week": 1, # Monday
                    "start_time": "10:00",
                    "end_time": "11:20",
                    "room_number": "Gates B01",
                    "instructor_name": "Prof. Julie Zelenski",
                    "class_type": "Lecture",
                    "created_at": now,
                    "updated_at": now,
                },
                {
                    "user_id": user_id,
                    "subject_id": cs107_id,
                    "day_of_week": 2, # Tuesday
                    "start_time": "13:30",
                    "end_time": "14:50",
                    "room_number": "Packard 101",
                    "instructor_name": "Prof. Jerry Cain",
                    "class_type": "Lecture",
                    "created_at": now,
                    "updated_at": now,
                },
                {
                    "user_id": user_id,
                    "subject_id": math51_id,
                    "day_of_week": 3, # Wednesday
                    "start_time": "09:00",
                    "end_time": "10:20",
                    "room_number": "Building 380 Room 380Y",
                    "instructor_name": "Prof. Brian Conrad",
                    "class_type": "Lecture",
                    "created_at": now,
                    "updated_at": now,
                }
            ])

            logger.info("Sample student account and academic workspace seeded successfully!")
    except Exception as e:
        logger.warning(f"Initial data seeding skipped or encountered error: {e}")
