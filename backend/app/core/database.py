import logging
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from app.core.config import settings

logger = logging.getLogger(__name__)


class DatabaseManager:
    client: AsyncIOMotorClient = None
    db: AsyncIOMotorDatabase = None


db_manager = DatabaseManager()


async def connect_to_mongo():
    """Initialize MongoDB connection pool and create essential indexes."""
    logger.info(f"Connecting to MongoDB at {settings.MONGODB_URL}...")
    try:
        db_manager.client = AsyncIOMotorClient(
            settings.MONGODB_URL,
            serverSelectionTimeoutMS=5000,
            maxPoolSize=50,
            minPoolSize=10
        )
        db_manager.db = db_manager.client[settings.DATABASE_NAME]
        # Ping the server to verify connectivity
        await db_manager.client.admin.command("ping")
        logger.info(f"Connected to MongoDB database: {settings.DATABASE_NAME}")

        # Create indexes
        await _create_indexes()
    except Exception as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        raise e


async def close_mongo_connection():
    """Close MongoDB connection pool."""
    if db_manager.client:
        logger.info("Closing MongoDB connection pool...")
        db_manager.client.close()
        logger.info("MongoDB connection closed.")


async def _create_indexes():
    """Ensure indexes for users, subjects, notes, and workspace collections."""
    try:
        users_collection = db_manager.db["users"]
        await users_collection.create_index("email", unique=True)
        await users_collection.create_index("created_at")

        subjects_collection = db_manager.db["subjects"]
        await subjects_collection.create_index([("user_id", 1), ("semester", 1)])
        await subjects_collection.create_index([("user_id", 1), ("code", 1)])
        await subjects_collection.create_index("is_archived")
        await subjects_collection.create_index("created_at")

        notes_collection = db_manager.db["notes"]
        await notes_collection.create_index([("user_id", 1), ("subject_id", 1)])
        await notes_collection.create_index([("user_id", 1), ("tags", 1)])
        await notes_collection.create_index([("user_id", 1), ("is_favorite", 1)])
        await notes_collection.create_index([("user_id", 1), ("is_pinned", 1)])
        await notes_collection.create_index("updated_at")

        files_collection = db_manager.db["files"]
        await files_collection.create_index([("user_id", 1), ("subject_id", 1)])
        await files_collection.create_index([("user_id", 1), ("folder_id", 1)])
        await files_collection.create_index([("user_id", 1), ("file_type", 1)])
        await files_collection.create_index([("user_id", 1), ("is_favorite", 1)])
        await files_collection.create_index("created_at")

        folders_collection = db_manager.db["folders"]
        await folders_collection.create_index([("user_id", 1), ("subject_id", 1)])
        await folders_collection.create_index([("user_id", 1), ("parent_id", 1)])
        await folders_collection.create_index("name")

        assignments_collection = db_manager.db["assignments"]
        await assignments_collection.create_index([("user_id", 1), ("subject_id", 1)])
        await assignments_collection.create_index([("user_id", 1), ("due_date", 1)])
        await assignments_collection.create_index([("user_id", 1), ("status", 1)])
        await assignments_collection.create_index([("user_id", 1), ("priority", 1)])
        await assignments_collection.create_index("created_at")

        exams_collection = db_manager.db["exams"]
        await exams_collection.create_index([("user_id", 1), ("subject_id", 1)])
        await exams_collection.create_index([("user_id", 1), ("date_time", 1)])
        await exams_collection.create_index([("user_id", 1), ("exam_type", 1)])
        await exams_collection.create_index("created_at")

        timetable_collection = db_manager.db["timetable_slots"]
        await timetable_collection.create_index([("user_id", 1), ("day_of_week", 1)])
        await timetable_collection.create_index([("user_id", 1), ("subject_id", 1)])
        await timetable_collection.create_index([("user_id", 1), ("start_time", 1)])

        attendance_collection = db_manager.db["attendance_logs"]
        await attendance_collection.create_index([("user_id", 1), ("date", 1)])
        await attendance_collection.create_index([("user_id", 1), ("subject_id", 1)])
        await attendance_collection.create_index([("user_id", 1), ("slot_id", 1)])

        notifications_collection = db_manager.db["notifications"]
        await notifications_collection.create_index([("user_id", 1), ("is_read", 1), ("created_at", -1)])
        await notifications_collection.create_index([("user_id", 1), ("type", 1)])
        await notifications_collection.create_index([("user_id", 1), ("dedup_key", 1)])

        chunks_collection = db_manager.db["document_chunks"]
        await chunks_collection.create_index([("user_id", 1), ("source_id", 1)])
        await chunks_collection.create_index([("user_id", 1), ("subject_id", 1)])
        await chunks_collection.create_index([("user_id", 1), ("source_type", 1)])
        await chunks_collection.create_index("created_at")

        status_collection = db_manager.db["ingestion_status"]
        await status_collection.create_index([("user_id", 1), ("source_id", 1)], unique=True)

        conversations_collection = db_manager.db["ai_conversations"]
        await conversations_collection.create_index([("user_id", 1), ("session_id", 1)], unique=True)
        await conversations_collection.create_index([("user_id", 1), ("updated_at", -1)])

        logger.info("MongoDB indexes for users, subjects, notes, files, assignments, exams, timetable, notifications, document chunks, and AI conversations verified successfully.")
    except Exception as e:
        logger.warning(f"Error creating indexes: {e}")



def get_database() -> AsyncIOMotorDatabase:
    """Dependency/helper to retrieve the database instance."""
    if db_manager.db is None:
        raise RuntimeError("Database connection has not been initialized.")
    return db_manager.db
