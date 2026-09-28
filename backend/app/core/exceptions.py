from fastapi import HTTPException, status

class EntityNotFoundError(HTTPException):
    def __init__(self, detail: str = "Resource not found"):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail)

class PermissionDeniedError(HTTPException):
    def __init__(self, detail: str = "You do not have permission to perform this action"):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail)

class InvalidStateTransitionError(HTTPException):
    def __init__(self, current_status: str, target_status: str, detail: str = ""):
        message = f"Invalid status transition from '{current_status}' to '{target_status}'"
        if detail:
            message += f": {detail}"
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, detail=message)

class BusinessRuleViolationError(HTTPException):
    def __init__(self, detail: str):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)

class AuthenticationError(HTTPException):
    def __init__(self, detail: str = "Could not validate credentials"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            headers={"WWW-Authenticate": "Bearer"},
        )
