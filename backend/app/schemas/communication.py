from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict
from app.schemas.user import UserOut

class CaseAttachmentOut(BaseModel):
    id: int
    case_id: int
    message_id: Optional[int] = None
    uploader_id: int
    file_name: str
    file_path: str
    file_size_bytes: int
    mime_type: str
    file_hash: Optional[str] = None
    created_at: datetime
    uploader: Optional[UserOut] = None

    model_config = ConfigDict(from_attributes=True)

class CaseMessageCreate(BaseModel):
    message: str
    is_information_request: bool = False
    is_ai_drafted: bool = False

class CaseMessageOut(BaseModel):
    id: int
    case_id: int
    sender_id: int
    message: str
    is_information_request: bool
    is_ai_drafted: bool
    created_at: datetime
    sender: Optional[UserOut] = None
    attachments: List[CaseAttachmentOut] = []

    model_config = ConfigDict(from_attributes=True)

class InternalNoteCreate(BaseModel):
    note: str

class InternalNoteOut(BaseModel):
    id: int
    case_id: int
    author_id: int
    note: str
    created_at: datetime
    author: Optional[UserOut] = None

    model_config = ConfigDict(from_attributes=True)
