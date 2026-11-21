from fastapi import APIRouter, HTTPException, Request, Response

router = APIRouter(tags=["cards"])


@router.get("/cards", responses={200: {"description": "cards.json, byte for byte"}, 304: {"description": "Unchanged"}})
def cards(request: Request) -> Response:
    """The shared cards.json. Send `If-None-Match` with the last ETag to skip unchanged data."""
    data = request.app.state.cards
    if data is None:
        raise HTTPException(503, "card data unavailable")
    headers = {"ETag": data.etag, "Cache-Control": "no-cache"}
    if request.headers.get("if-none-match") == data.etag:
        return Response(status_code=304, headers=headers)
    return Response(content=data.raw, media_type="application/json", headers=headers)
