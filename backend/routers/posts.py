from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from pydantic import BaseModel
from typing import List, Dict
from backend.models.database import get_db
from backend.models.post import Post, Comment

router = APIRouter(prefix="/posts", tags=["posts"])

# ── 요청 데이터 스키마 ────────────────────────────────

class PostCreate(BaseModel):
    # 게시판 카테고리
    category: str
    # 게시글 제목
    title: str
    # 게시글 내용
    content: str
    # 작성자 닉네임
    author: str

class CommentCreate(BaseModel):
    # 댓글 내용
    content: str
    # 작성자 닉네임
    author: str

# ── HTTP API ──────────────────────────────────────────

# 카테고리별 게시글 목록 조회
@router.get("/{category}")
async def get_posts(category: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Post)
        .where(Post.category == category)
        # 최신순 정렬
        .order_by(Post.created_at.desc())
    )
    posts = result.scalars().all()
    return {"posts": [
        {
            "id": p.id,
            "title": p.title,
            "author": p.author,
            "views": p.views,
            "created_at": p.created_at.strftime("%Y.%m.%d %H:%M"),
        }
        for p in posts
    ]}

# 게시글 상세 조회 (조회수 증가)
@router.get("/detail/{post_id}")
async def get_post(post_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Post).where(Post.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다")

    # 조회수 증가
    await db.execute(
        update(Post).where(Post.id == post_id).values(views=Post.views + 1)
    )
    await db.commit()

    # 댓글 목록도 함께 반환
    comment_result = await db.execute(
        select(Comment)
        .where(Comment.post_id == post_id)
        .order_by(Comment.created_at.asc())
    )
    comments = comment_result.scalars().all()

    return {
        "id": post.id,
        "category": post.category,
        "title": post.title,
        "content": post.content,
        "author": post.author,
        "views": post.views + 1,
        "created_at": post.created_at.strftime("%Y.%m.%d %H:%M"),
        "comments": [
            {
                "id": c.id,
                "content": c.content,
                "author": c.author,
                "created_at": c.created_at.strftime("%Y.%m.%d %H:%M"),
            }
            for c in comments
        ],
    }

# 게시글 작성
@router.post("")
async def create_post(req: PostCreate, db: AsyncSession = Depends(get_db)):
    # 제목/내용 빈 값 체크
    if not req.title.strip() or not req.content.strip():
        raise HTTPException(status_code=400, detail="제목과 내용을 입력해주세요")

    new_post = Post(
        category=req.category,
        title=req.title,
        content=req.content,
        author=req.author,
    )
    db.add(new_post)
    await db.commit()
    await db.refresh(new_post)
    return {"message": "게시글이 등록됐습니다", "id": new_post.id}

# 게시글 삭제
@router.delete("/{post_id}")
async def delete_post(post_id: int, author: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Post).where(Post.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다")
    # 작성자만 삭제 가능
    if post.author != author:
        raise HTTPException(status_code=403, detail="삭제 권한이 없습니다")
    await db.delete(post)
    await db.commit()
    return {"message": "게시글이 삭제됐습니다"}

# 댓글 작성
@router.post("/{post_id}/comments")
async def create_comment(
    post_id: int,
    req: CommentCreate,
    db: AsyncSession = Depends(get_db),
):
    # 게시글 존재 여부 확인
    result = await db.execute(select(Post).where(Post.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다")

    new_comment = Comment(
        post_id=post_id,
        content=req.content,
        author=req.author,
    )
    db.add(new_comment)
    await db.commit()
    await db.refresh(new_comment)
    return {
        "id": new_comment.id,
        "content": new_comment.content,
        "author": new_comment.author,
        "created_at": new_comment.created_at.strftime("%Y.%m.%d %H:%M"),
    }

# ── WebSocket (실시간 댓글) ────────────────────────────

# 게시글별 WebSocket 연결 관리
class CommentManager:
    def __init__(self):
        # {post_id: [ws1, ws2, ...]} 형태
        self.connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, post_id: int):
        await websocket.accept()
        if post_id not in self.connections:
            self.connections[post_id] = []
        self.connections[post_id].append(websocket)

    def disconnect(self, websocket: WebSocket, post_id: int):
        if post_id in self.connections:
            self.connections[post_id].remove(websocket)

    async def broadcast(self, message: str, post_id: int):
        # 같은 게시글 보는 사람들에게만 댓글 실시간 전송
        for ws in self.connections.get(post_id, []):
            await ws.send_text(message)

comment_manager = CommentManager()

# 게시글 댓글 실시간 WebSocket
@router.websocket("/ws/{post_id}/{username}")
async def comment_websocket(
    websocket: WebSocket,
    post_id: int,
    username: str,
    db: AsyncSession = Depends(get_db),
):
    await comment_manager.connect(websocket, post_id)
    try:
        while True:
            # 클라이언트에서 댓글 내용 수신
            data = await websocket.receive_text()

            # DB에 댓글 저장
            new_comment = Comment(
                post_id=post_id,
                content=data,
                author=username,
            )
            db.add(new_comment)
            await db.commit()
            await db.refresh(new_comment)

            # 같은 게시글 보는 사람들에게 실시간 전송
            import json
            await comment_manager.broadcast(
                json.dumps({
                    "author": username,
                    "content": data,
                    "created_at": new_comment.created_at.strftime("%Y.%m.%d %H:%M"),
                }, ensure_ascii=False),
                post_id,
            )
    except WebSocketDisconnect:
        comment_manager.disconnect(websocket, post_id)