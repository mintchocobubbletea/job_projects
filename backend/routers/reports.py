# reports.py
# 신고 관련 API 라우터
# 게시글/댓글 신고 접수 및 자동 제재 처리
# 신고 누적 횟수에 따라 게시글/댓글 자동 숨김 처리

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, update
from pydantic import BaseModel

from backend.models.database import get_db
from backend.models.report import Report
from backend.models.post import Post, Comment

# /reports 접두사로 모든 엔드포인트 등록
router = APIRouter(prefix="/reports", tags=["reports"])

# ── 자동 제재 임계값 설정 ─────────────────────────────
# 신고 30회 이상: 해당 게시글/댓글 자동 숨김
HIDE_THRESHOLD = 30
# 신고 50회 이상: 신고 대상자의 모든 게시글 숨김 (계정 제재)
BAN_THRESHOLD = 50

# ── 요청 데이터 스키마 ────────────────────────────────

class ReportRequest(BaseModel):
    # 신고 유형 ("post": 게시글 신고, "comment": 댓글 신고)
    report_type: str
    # 신고 대상 ID (게시글 ID 또는 댓글 ID)
    target_id: int
    # 신고 사유 (욕설/비방, 스팸/광고, 개인정보 유출, 불쾌한 언행, 허위 정보, 기타)
    reason: str
    # 신고자 닉네임
    reporter: str

# ── 신고 접수 API ─────────────────────────────────────

@router.post("")
async def create_report(req: ReportRequest, db: AsyncSession = Depends(get_db)):
    """
    신고 접수 API
    처리 순서:
    1. 신고 유형 유효성 검사 (post 또는 comment만 허용)
    2. 신고 대상 존재 여부 확인
    3. 자기 자신 신고 방지
    4. 중복 신고 방지 (같은 사용자가 같은 게시물 중복 신고 불가)
    5. 신고 DB 저장
    6. 신고 누적 횟수 확인 후 자동 제재 처리
       - 30회 이상: 해당 게시글/댓글 숨김
       - 50회 이상: 신고 대상자의 모든 게시글 숨김
    """
    # 신고 유형 유효성 검사
    if req.report_type not in ["post", "comment"]:
        raise HTTPException(status_code=400, detail="잘못된 신고 유형입니다")

    # 신고 대상 존재 여부 확인 및 작성자 조회
    if req.report_type == "post":
        result = await db.execute(select(Post).where(Post.id == req.target_id))
    else:
        result = await db.execute(
            select(Comment).where(Comment.id == req.target_id)
        )
    target = result.scalar_one_or_none()

    if not target:
        raise HTTPException(status_code=404, detail="신고 대상을 찾을 수 없습니다")

    # 자기 자신 신고 방지
    if target.author == req.reporter:
        raise HTTPException(status_code=400, detail="자신의 글은 신고할 수 없습니다")

    # 중복 신고 방지 (같은 사용자가 같은 게시물에 이미 신고한 경우)
    existing = await db.execute(
        select(Report).where(
            Report.report_type == req.report_type,
            Report.target_id == req.target_id,
            Report.reporter == req.reporter,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="이미 신고한 게시물입니다")

    # 신고 내역 DB에 저장
    new_report = Report(
        report_type=req.report_type,
        target_id=req.target_id,
        reason=req.reason,
        reporter=req.reporter,
        reported_user=target.author,
    )
    db.add(new_report)
    await db.commit()

    # 해당 게시글/댓글의 총 신고 횟수 조회
    count_result = await db.execute(
        select(func.count(Report.id)).where(
            Report.report_type == req.report_type,
            Report.target_id == req.target_id,
        )
    )
    report_count = count_result.scalar()

    # 신고 30회 이상: 해당 게시글/댓글 자동 숨김 처리
    if report_count >= HIDE_THRESHOLD:
        if req.report_type == "post":
            await db.execute(
                update(Post)
                .where(Post.id == req.target_id)
                .values(is_hidden=True)
            )
        else:
            await db.execute(
                update(Comment)
                .where(Comment.id == req.target_id)
                .values(is_hidden=True)
            )
        await db.commit()

    # 신고 50회 이상: 신고 대상자의 모든 게시글 숨김 (계정 제재)
    if report_count >= BAN_THRESHOLD:
        await db.execute(
            update(Post)
            .where(Post.author == target.author)
            .values(is_hidden=True)
        )
        await db.commit()

    return {"message": "신고가 접수됐습니다"}