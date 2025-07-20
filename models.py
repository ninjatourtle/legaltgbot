import sqlalchemy as sa
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base, relationship
from config import settings

Base = declarative_base()
engine = create_async_engine(settings.DATABASE_URL, echo=False)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

class User(Base):
    __tablename__ = "users"
    id = sa.Column(sa.Integer, primary_key=True)
    telegram_id = sa.Column(sa.BigInteger, unique=True, index=True)

class Document(Base):
    __tablename__ = "documents"
    id = sa.Column(sa.Integer, primary_key=True)
    user_id = sa.Column(sa.Integer, sa.ForeignKey("users.id"), nullable=False)
    file_path = sa.Column(sa.String, nullable=False)
    extracted_text = sa.Column(sa.Text, nullable=False)
    page_count = sa.Column(sa.Integer, nullable=False)
    is_paid = sa.Column(sa.Boolean, default=False, nullable=False)
    analysis = sa.Column(sa.JSON, nullable=True)
    analyzed_at = sa.Column(
        sa.DateTime(timezone=True),
        server_default=sa.func.now(),
        nullable=True
    )

    user = relationship("User", back_populates="documents")

User.documents = relationship("Document", order_by=Document.id, back_populates="user")
