# posts.py
# 게시글 및 댓글 관련 API 라우터
# 게시글 CRUD, 댓글 작성, 실시간 댓글 WebSocket 제공
# WebSocket을 통해 같은 게시글을 보는 사용자들에게 실시간으로 댓글 전송

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from pydantic import BaseModel
from typing import List, Dict
import json

from backend.models.database import get_db
from backend.models.post import Post, Comment

# /posts 접두사로 모든 엔드포인트 등록
router = APIRouter(prefix="/posts", tags=["posts"])

# ── 요청 데이터 스키마 ────────────────────────────────

class PostCreate(BaseModel):
    # 게시판 카테고리 (면접 꿀팁, 자기소개서, 취업 후기, 프로그램 후기, 취업 고민)
    category: str
    # 게시글 제목
    title: str
    # 게시글 본문 내용
    content: str
    # 작성자 닉네임
    author: str

class CommentCreate(BaseModel):
    # 댓글 내용
    content: str
    # 작성자 닉네임
    author: str

# ── HTTP API ──────────────────────────────────────────

@router.get("/{category}")
async def get_posts(category: str, db: AsyncSession = Depends(get_db)):
    """
    카테고리별 게시글 목록 조회 API
    - 숨김 처리된 게시글(is_hidden=True) 제외
    - 최신순(작성일 내림차순) 정렬
    - 목록에는 제목, 작성자, 조회수, 작성일만 반환 (본문 제외)
    """
    result = await db.execute(
        select(Post)
        .where(Post.category == category)
        # 신고로 숨김 처리된 게시글 제외
        .where(Post.is_hidden == False)
        # 최신 게시글이 위에 표시되도록 내림차순 정렬
        .order_by(Post.created_at.desc())
    )
    posts = result.scalars().all()
    return {"posts": [
        {
            "id": p.id,
            "title": p.title,
            "author": p.author,
            "views": p.views,
            # 날짜 포맷: 2026.05.01 14:30
            "created_at": p.created_at.strftime("%Y.%m.%d %H:%M"),
        }
        for p in posts
    ]}

@router.get("/detail/{post_id}")
async def get_post(post_id: int, db: AsyncSession = Depends(get_db)):
    """
    게시글 상세 조회 API
    - 조회 시 조회수 1 증가
    - 숨김 처리된 게시글 접근 차단
    - 숨김 처리된 댓글 제외하고 반환
    - 댓글은 작성 시간 오름차순 정렬 (오래된 댓글이 위)
    """
    # 게시글 조회
    result = await db.execute(select(Post).where(Post.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다")

    # 신고로 숨김 처리된 게시글 접근 차단
    if post.is_hidden:
        raise HTTPException(
            status_code=403,
            detail="신고로 인해 숨김 처리된 게시글입니다"
        )

    # 조회수 1 증가
    await db.execute(
        update(Post).where(Post.id == post_id).values(views=Post.views + 1)
    )
    await db.commit()

    # 숨김 처리되지 않은 댓글만 조회 (오래된 순)
    comment_result = await db.execute(
        select(Comment)
        .where(Comment.post_id == post_id)
        .where(Comment.is_hidden == False)
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

@router.post("")
async def create_post(req: PostCreate, db: AsyncSession = Depends(get_db)):
    """
    게시글 작성 API
    - 제목과 내용이 비어있으면 400 에러 반환
    - 작성 성공 시 게시글 ID 반환
    """
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

@router.delete("/{post_id}")
async def delete_post(post_id: int, author: str, db: AsyncSession = Depends(get_db)):
    """
    게시글 삭제 API
    - 작성자 본인만 삭제 가능
    - 다른 사용자가 삭제 시도 시 403 에러 반환
    """
    result = await db.execute(select(Post).where(Post.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다")

    # 작성자 본인만 삭제 가능
    if post.author != author:
        raise HTTPException(status_code=403, detail="삭제 권한이 없습니다")

    await db.delete(post)
    await db.commit()
    return {"message": "게시글이 삭제됐습니다"}

@router.post("/{post_id}/comments")
async def create_comment(
    post_id: int,
    req: CommentCreate,
    db: AsyncSession = Depends(get_db),
):
    """
    댓글 작성 HTTP API
    - WebSocket 연결이 불가능한 경우 사용
    - 게시글 존재 여부 확인 후 댓글 저장
    """
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

class CommentManager:
    """
    게시글별 WebSocket 연결 관리 클래스
    - 같은 게시글을 보는 사용자들의 WebSocket 연결을 관리
    - 새 댓글 작성 시 같은 게시글을 보는 모든 사용자에게 실시간 전송
    - TCP 기반의 WebSocket 프로토콜 사용
    """
    def __init__(self):
        # {post_id: [ws1, ws2, ...]} 형태로 게시글별 연결 관리
        self.connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, post_id: int):
        """WebSocket 연결 수락 및 게시글 연결 목록에 추가"""
        await websocket.accept()
        if post_id not in self.connections:
            self.connections[post_id] = []
        self.connections[post_id].append(websocket)

    def disconnect(self, websocket: WebSocket, post_id: int):
        """WebSocket 연결 해제 시 게시글 연결 목록에서 제거"""
        if post_id in self.connections:
            self.connections[post_id].remove(websocket)

    async def broadcast(self, message: str, post_id: int):
        """
        같은 게시글을 보는 모든 사용자에게 메시지 브로드캐스트
        - 다른 게시글을 보는 사용자에게는 전송하지 않음
        """
        for ws in self.connections.get(post_id, []):
            await ws.send_text(message)

# 앱 전체에서 하나의 CommentManager 인스턴스 사용
comment_manager = CommentManager()

@router.websocket("/ws/{post_id}/{username}")
async def comment_websocket(
    websocket: WebSocket,
    post_id: int,
    username: str,
    db: AsyncSession = Depends(get_db),
):
    """
    실시간 댓글 WebSocket 엔드포인트
    - TCP 기반 WebSocket 프로토콜로 클라이언트와 지속적인 연결 유지
    - 댓글 작성 시 DB에 저장하고 같은 게시글 보는 모든 사용자에게 실시간 전송
    
    동작 흐름:
    1. 클라이언트가 게시글 상세 화면 진입 시 WebSocket 연결
    2. 댓글 입력 후 전송 시 서버로 텍스트 전달
    3. 서버에서 DB에 댓글 저장
    4. 같은 게시글을 보는 모든 클라이언트에게 새 댓글 브로드캐스트
    5. 게시글 화면 이탈 시 WebSocket 연결 해제
    """
    # 1. WebSocket 연결 수락 및 게시글 연결 목록에 추가
    await comment_manager.connect(websocket, post_id)
    try:
        while True:
            # 2. 클라이언트로부터 댓글 내용 수신
            data = await websocket.receive_text()

            # 3. 수신한 댓글을 DB에 저장
            new_comment = Comment(
                post_id=post_id,
                content=data,
                author=username,
            )
            db.add(new_comment)
            await db.commit()
            await db.refresh(new_comment)

            # 4. 같은 게시글을 보는 모든 클라이언트에게 댓글 브로드캐스트
            # JSON 형식으로 작성자, 내용, 작성 시간 전송
            await comment_manager.broadcast(
                json.dumps({
                    "id": new_comment.id,
                    "author": username,
                    "content": data,
                    "created_at": new_comment.created_at.strftime(
                        "%Y.%m.%d %H:%M"
                    ),
                }, ensure_ascii=False),
                post_id,
            )
    except WebSocketDisconnect:
        # 5. 클라이언트 연결 해제 시 목록에서 제거
        comment_manager.disconnect(websocket, post_id)