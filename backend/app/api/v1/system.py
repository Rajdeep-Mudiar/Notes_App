import logging
from typing import Optional
from fastapi import APIRouter, Query
import requests
from app.core.config import settings
from app.schemas.response import ApiResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/system", tags=["System & Updates"])

CURRENT_APP_VERSION = "1.0.0"
GITHUB_REPO = "Rajdeep-Mudiar/Notes_App"
LATEST_RELEASE_URL = f"https://github.com/{GITHUB_REPO}/releases/latest"


@router.get("/version", response_model=ApiResponse[dict])
async def get_version_info():
    """Retrieve system version and release update metadata."""
    return ApiResponse(
        success=True,
        message="System version metadata retrieved successfully.",
        data={
            "app_version": CURRENT_APP_VERSION,
            "min_supported_version": "1.0.0",
            "github_repo": GITHUB_REPO,
            "release_url": LATEST_RELEASE_URL,
            "backend_version": settings.VERSION,
            "environment": settings.ENVIRONMENT,
        },
    )


@router.get("/check-update", response_model=ApiResponse[dict])
async def check_app_update(client_version: Optional[str] = Query(None, description="Client app version")):
    """Check GitHub releases for updates against the client's current version."""
    current_ver = (client_version or CURRENT_APP_VERSION).lstrip("v").strip()
    update_available = False
    latest_version = CURRENT_APP_VERSION
    download_url = LATEST_RELEASE_URL
    release_notes = "Performance improvements and new study tools."

    try:
        # Check GitHub Releases API
        api_url = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"
        resp = requests.get(api_url, timeout=5, headers={"User-Agent": "StudentOS-App"})
        if resp.status_code == 200:
            data = resp.json()
            tag_name = data.get("tag_name", "").lstrip("v").strip()
            if tag_name:
                latest_version = tag_name
                release_notes = data.get("body", release_notes)
                # Check for APK asset download link
                assets = data.get("assets", [])
                for asset in assets:
                    if asset.get("name", "").endswith(".apk"):
                        download_url = asset.get("browser_download_url", download_url)
                        break
                if download_url == LATEST_RELEASE_URL:
                    download_url = data.get("html_url", LATEST_RELEASE_URL)

                # Compare version numbers (major.minor.patch)
                def parse_ver(v_str: str):
                    parts = []
                    for p in v_str.split("+")[0].split("."):
                        try:
                            parts.append(int(p))
                        except ValueError:
                            parts.append(0)
                    while len(parts) < 3:
                        parts.append(0)
                    return parts

                client_parts = parse_ver(current_ver)
                latest_parts = parse_ver(latest_version)

                if latest_parts > client_parts:
                    update_available = True
    except Exception as e:
        logger.warning(f"Failed to query GitHub Releases API: {e}")

    return ApiResponse(
        success=True,
        message="Update status checked.",
        data={
            "update_available": update_available,
            "current_version": current_ver,
            "latest_version": latest_version,
            "download_url": download_url,
            "release_notes": release_notes,
            "is_mandatory": False,
        },
    )
