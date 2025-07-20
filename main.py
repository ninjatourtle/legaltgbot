import asyncio
import logging
import datetime
import os

from aiogram import Bot, Dispatcher, F, types
from aiogram.filters import Command
from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton, FSInputFile
from sqlalchemy import select

from config import settings
from models import Base, engine, AsyncSessionLocal, User, Document
from services.pdf_parser import parse_pdf
from services.docx_parser import parse_docx
from services.html_report_generator import generate_report_pdf
from services.llm_client import analyze_contract

logging.basicConfig(level=logging.INFO)
bot = Bot(token=settings.TELEGRAM_TOKEN, parse_mode="HTML")
dp = Dispatcher()

async def on_startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    me = await bot.get_me()
    logging.info(f"✅ Bot started as @{me.username}")

async def get_or_create_user(session: AsyncSessionLocal, tg_id: int) -> User:
    result = await session.execute(select(User).where(User.telegram_id == tg_id))
    user = result.scalars().first()
    if not user:
        user = User(telegram_id=tg_id)
        session.add(user)
        await session.commit()
        await session.refresh(user)
    return user

@dp.message(Command("start"))
async def cmd_start(msg: types.Message):
    await msg.answer(
        "👋 Привет! Я — бот для анализа договоров.\n"
        "Отправь PDF или DOCX, я посчитаю страницы и предложу кнопку «Я оплатил» для тестирования.\n"
        "После нажатия кнопки выполню анализ."
    )
    history_kb = InlineKeyboardMarkup(
        inline_keyboard=[
            [InlineKeyboardButton(text="История анализов", callback_data="show_history")]
        ]
    )
    await msg.answer(
        "Нажмите кнопку «История анализов» для просмотра списка ваших отчётов.",
        reply_markup=history_kb
    )

@dp.message(F.text)
async def echo(msg: types.Message):
    await msg.answer(f"✅ Получил сообщение: {msg.text}")

@dp.message(F.document)
async def handle_document(msg: types.Message):
    async with AsyncSessionLocal() as session:
        user = await get_or_create_user(session, msg.from_user.id)
        file = await bot.get_file(msg.document.file_id)
        ext = msg.document.file_name.rsplit('.', 1)[-1].lower()
        path = f"downloads/{msg.document.file_unique_id}.{ext}"
        await bot.download_file(file.file_path, destination=path)

        if ext == "pdf":
            text, page_count = await parse_pdf(path)
        elif ext in ("docx", "doc"):
            text, page_count = await parse_docx(path)
        else:
            return await msg.answer("❌ Только PDF и DOCX.")

        if not text.strip():
            return await msg.answer(
                "⚠️ Не удалось извлечь текст. Пожалуйста, отправьте текст документа."
            )

        doc = Document(
            user_id=user.id,
            file_path=path,
            extracted_text=text,
            page_count=page_count,
            is_paid=False
        )
        session.add(doc)
        await session.commit()
        await session.refresh(doc)

        markup = InlineKeyboardMarkup(
            inline_keyboard=[
                [InlineKeyboardButton(text="Я оплатил", callback_data=f"paid:{doc.id}")]
            ]
        )
        await msg.answer(
            f"📄 Страниц: <b>{page_count}</b>. Нажмите «Я оплатил».",
            reply_markup=markup
        )

@dp.callback_query(F.data.startswith("paid:"))
async def handle_paid(callback: types.CallbackQuery):
    doc_id = int(callback.data.split(':', 1)[1])
    async with AsyncSessionLocal() as session:
        doc = await session.get(Document, doc_id)
        if not doc or doc.is_paid:
            return await callback.answer("Документ не найден или уже обработан.")
        doc.is_paid = True
        await callback.answer("Оплата отмечена, анализирую…")
        result = await analyze_contract(doc.extracted_text)
        doc.analysis = {"result": result}
        doc.analyzed_at = datetime.datetime.utcnow()
        session.add(doc)
        await session.commit()

    # Генерируем PDF-отчёт и отправляем его
    pdf_path = f"report_{doc_id}.pdf"
    generate_report_pdf(doc, doc.analysis, pdf_path)
    await callback.message.answer_document(
        FSInputFile(pdf_path, filename=f"report_{doc_id}.pdf"),
        caption="📄 Полный отчёт по анализу"
    )
    os.remove(pdf_path)

@dp.callback_query(F.data == "show_history")
async def show_history(callback: types.CallbackQuery):
    async with AsyncSessionLocal() as session:
        user_res = await session.execute(
            select(User).where(User.telegram_id == callback.from_user.id)
        )
        user = user_res.scalars().first()
        if not user:
            return await callback.answer("У вас нет истории анализов.", show_alert=True)
        docs_res = await session.execute(
            select(Document)
            .where(
                Document.user_id == user.id,
                Document.is_paid == True,
                Document.analysis.is_not(None)
            )
            .order_by(Document.analyzed_at.desc())
        )
        docs = docs_res.scalars().all()

    if not docs:
        return await callback.answer("У вас нет истории анализов.", show_alert=True)

    lines = []
    for doc in docs:
        date = doc.analyzed_at.strftime("%Y-%m-%d %H:%M")
        snippet = doc.analysis["result"][:100].replace("\n"," ")
        lines.append(f"{date} — #{doc.id}: {snippet}...")
    await callback.message.answer(
        "📜 <b>История анализов:</b>\n" + "\n".join(lines),
        parse_mode="HTML"
    )

if __name__ == "__main__":
    logging.info("🚀 Initializing database…")
    logging.info("🚀 Starting polling…")
    dp.run_polling(bot, on_startup=on_startup)