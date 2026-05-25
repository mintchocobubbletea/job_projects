from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
from backend.models.database import get_db
from backend.models.report import Report
from backend.models.post import Post, Comment

router = APIRouter(prefix="/reports", tags=["reports"])

# 신고 요청 스키마
class ReportRequest(BaseModel):
    # 신고 유형 (post 또는 comment)
    report_type: str
    # 신고 대상 ID
    target_id: int
    # 신고 사유
    reason: str
    # 신고자 닉네임
    reporter: str

# 신고 접수
@router.post("")
async def create_report(req: ReportRequest, db: AsyncSession = Depends(get_db)):
    # 신고 유형 유효성 검사
    if req.report_type not in ["post", "comment"]:
        raise HTTPException(status_code=400, detail="잘못된 신고 유형입니다")

    # 신고 대상 존재 여부 확인 및 작성자 조회
    if req.report_type == "post":
        result = await db.execute(select(Post).where(Post.id == req.target_id))
        target = result.scalar_one_or_none()
    else:
        result = await db.execute(select(Comment).where(Comment.id == req.target_id))
        target = result.scalar_one_or_none()

    if not target:
        raise HTTPException(status_code=404, detail="신고 대상을 찾을 수 없습니다")

    # 자기 자신 신고 방지
    if target.author == req.reporter:
        raise HTTPException(status_code=400, detail="자신의 글은 신고할 수 없습니다")

    # 중복 신고 확인
    existing = await db.execute(
        select(Report).where(
            Report.report_type == req.report_type,
            Report.target_id == req.target_id,
            Report.reporter == req.reporter,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="이미 신고한 게시물입니다")

    # 신고 저장
    new_report = Report(
        report_type=req.report_type,
        target_id=req.target_id,
        reason=req.reason,
        reporter=req.reporter,
        reported_user=target.author,
    )
    db.add(new_report)
    await db.commit()
    return {"message": "신고가 접수됐습니다"}