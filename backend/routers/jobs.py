from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.models.database import get_db
from backend.models.job import Job

router = APIRouter(prefix="/jobs", tags=["jobs"])

@router.get("")
async def get_jobs(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Job))
    jobs = result.scalars().all()
    return {"jobs": [
        {
            "id": job.id,
            "title": job.title,
            "company": job.company,
            "location": job.location,
            "description": job.description,
        }
        for job in jobs
    ]}

@router.get("/{job_id}")
async def get_job(job_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Job).where(Job.id == job_id))
    job = result.scalar_one_or_none()
    if job is None:
        raise HTTPException(status_code=404, detail="공고를 찾을 수 없습니다")
    return {
        "id": job.id,
        "title": job.title,
        "company": job.company,
        "location": job.location,
        "description": job.description,
    }

@router.post("")
async def create_job(
    title: str,
    company: str,
    location: str,
    description: str = "",
    db: AsyncSession = Depends(get_db),
):
    new_job = Job(
        title=title,
        company=company,
        location=location,
        description=description,
    )
    db.add(new_job)
    await db.commit()
    await db.refresh(new_job)
    return new_job

@router.delete("/{job_id}")
async def delete_job(job_id: int, db: AsyncSession = Depends(get_db)):
    # 삭제할 공고 조회
    result = await db.execute(select(Job).where(Job.id == job_id))
    job = result.scalar_one_or_none()
    if job is None:
        raise HTTPException(status_code=404, detail="공고를 찾을 수 없습니다")
    # DB에서 삭제
    await db.delete(job)
    await db.commit()
    return {"message": f"{job.title} 공고가 삭제됐습니다"}