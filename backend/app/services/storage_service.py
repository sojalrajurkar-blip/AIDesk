import os
import hashlib
from typing import Tuple, Optional
from datetime import datetime
import httpx
from fastapi import UploadFile

from app.core.config import settings

class StorageService:
    """
    Handles file storage using Supabase Storage with seamless local fallback.
    - If SUPABASE_URL and SUPABASE_KEY are provided: Uploads to Supabase Storage bucket.
    - If not configured or network offline: Saves locally to UPLOAD_DIR.
    """

    async def upload_file(self, file: UploadFile) -> Tuple[str, str, int, str]:
        """
        Uploads a file and returns: (file_path_or_url, file_hash, file_size_bytes, mime_type)
        """
        content = await file.read()
        file_size = len(content)
        file_hash = hashlib.sha256(content).hexdigest()
        mime_type = file.content_type or "application/octet-stream"

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_filename = f"{timestamp}_{file.filename or 'file'}"

        # 1. Attempt Supabase Storage Upload if configured
        if settings.SUPABASE_URL and settings.SUPABASE_KEY:
            try:
                base_url = settings.SUPABASE_URL.rstrip('/')
                bucket = settings.SUPABASE_BUCKET
                upload_url = f"{base_url}/storage/v1/object/{bucket}/{safe_filename}"
                headers = {
                    "Authorization": f"Bearer {settings.SUPABASE_KEY}",
                    "apikey": settings.SUPABASE_KEY,
                    "Content-Type": mime_type
                }
                async with httpx.AsyncClient(timeout=30.0) as client:
                    resp = await client.post(upload_url, content=content, headers=headers)
                    # If bucket does not exist, auto-create it with service_role key
                    if resp.status_code in [400, 404]:
                        create_bucket_url = f"{base_url}/storage/v1/bucket"
                        await client.post(
                            create_bucket_url,
                            json={"id": bucket, "name": bucket, "public": True},
                            headers=headers
                        )
                        # Retry upload
                        resp = await client.post(upload_url, content=content, headers=headers)

                    if resp.status_code in [200, 201]:
                        public_url = f"{base_url}/storage/v1/object/public/{bucket}/{safe_filename}"
                        return public_url, file_hash, file_size, mime_type
            except Exception:
                pass  # Gracefully fall back to local disk storage

        # 2. Local Disk Storage Fallback
        os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
        local_path = os.path.join(settings.UPLOAD_DIR, safe_filename)
        with open(local_path, "wb") as f:
            f.write(content)

        return local_path, file_hash, file_size, mime_type

storage_service = StorageService()
