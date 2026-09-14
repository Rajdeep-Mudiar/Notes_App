import asyncio
import httpx
import pytest
from app.main import app
from app.core.database import connect_to_mongo, close_mongo_connection, get_database

# We will write a standalone verification script to test live endpoints
