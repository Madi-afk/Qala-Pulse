from starlette.types import ASGIApp, Message, Receive, Scope, Send

from app.core.errors import fail


class RequestSizeLimit:
    """Count bytes as they arrive, including chunked multipart uploads."""

    def __init__(self, app: ASGIApp, limit: int) -> None:
        self.app, self.limit = app, limit

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        size = 0

        async def limited_receive() -> Message:
            nonlocal size
            message = await receive()
            size += len(message.get("body", b""))
            if size > self.limit:
                raise fail("file_too_large", "Запрос превышает лимит", 413)
            return message

        await self.app(scope, limited_receive, send)
