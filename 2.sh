#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Скрипт для добавления кнопки "История анализов" и хендлера в main.py
# ----------------------------------------------------------
MAIN="main.py"

if [[ ! -f "$MAIN" ]]; then
  echo "❌ $MAIN не найден. Запустите скрипт из корня проекта."
  exit 1
fi

# 1) Убедимся, что импорт select есть
grep -q "from sqlalchemy import select" "$MAIN" \
  || sed -i "1ifrom sqlalchemy import select" "$MAIN"

# 2) Вставляем кнопку "История анализов" в /start handler
sed -i "/@dp.message(Command(\"start\"))/,/async def cmd_start/ {
    /await msg.answer/ a\
        markup = InlineKeyboardMarkup(inline_keyboard=[[InlineKeyboardButton(\"История анализов\", callback_data=\"show_history\")]])\
        await msg.answer(\"Нажмите кнопку «История анализов» для просмотра истории.\", reply_markup=markup)
}" "$MAIN"

# 3) Вставляем callback-хендлер для show_history перед основным блоком запуска
sed -i "/if __name__ == \"__main__\"/ i\
@dp.callback_query(F.data == \"show_history\")\
async def show_history(callback: types.CallbackQuery):\
    \"\"\"Показывает список всех ваших проведённых анализов.\"\"\"\
    async with AsyncSessionLocal() as session:\
        result = await session.execute(\
            select(Document).where(\
                Document.user_id == callback.from_user.id,\
                Document.is_paid == True,\
                Document.analysis != None\
            )\
        )\
        docs = result.scalars().all()\
        if not docs:\
            return await callback.answer(\"У вас нет истории анализов.\", show_alert=True)\
        lines = []\
        for doc in docs:\
            snippet = doc.analysis.get(\"result\", \"\")[:200].replace(\"\\n\", \" \")\
            lines.append(f\"# {doc.id}: {snippet}...\")\
        text = \"📜 История анализов:\\n\" + \"\\n\".join(lines)\
        await callback.message.answer(text)\
" "$MAIN"

echo "✅ main.py обновлён: добавлены кнопка и handler истории анализов."
echo "▶️ Перезапустите бота: python main.py"

