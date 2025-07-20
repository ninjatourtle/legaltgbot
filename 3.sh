#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Скрипт для правки main.py: добавление кнопки "История анализов"
# и корректного handler'а show_history
# ----------------------------------------------------------
MAIN="main.py"
TMP="main.tmp"

if [[ ! -f "$MAIN" ]]; then
  echo "❌ $MAIN не найден. Запустите скрипт из корня проекта."
  exit 1
fi

# 1) Убедимся, что импорт select у нас есть
grep -q "from sqlalchemy import select" "$MAIN" \
  || sed -i '1ifrom sqlalchemy import select' "$MAIN"

# 2) Добавляем кнопку в cmd_start
#    После строки await msg.answer(...)\n вставляем две новые строчки с кнопкой
awk '
/^@dp\.message\(Command\("start"\)\)/ { in_start=1 }
in_start && /await msg\.answer/ && !added_button {
    print
    print "    history_kb = InlineKeyboardMarkup(inline_keyboard=[[InlineKeyboardButton(\"История анализов\", callback_data=\"show_history\")]])"
    print "    await msg.answer(\"Нажмите кнопку «История анализов» для просмотра истории.\", reply_markup=history_kb)"
    added_button=1
    next
}
{ print }
' "$MAIN" > "$TMP" && mv "$TMP" "$MAIN"

# 3) Вставляем handler show_history перед концом файла (перед if __name__)
#    Если он ещё не был вставлен
grep -q "async def show_history" "$MAIN" \
  || cat >> "$MAIN" << 'EOF'


@dp.callback_query(F.data == "show_history")
async def show_history(callback: types.CallbackQuery):
    """Показывает список всех проведённых анализов пользователя."""
    async with AsyncSessionLocal() as session:
        result = await session.execute(
            select(Document).where(
                Document.user_id == callback.from_user.id,
                Document.is_paid == True,
                Document.analysis != None
            )
        )
        docs = result.scalars().all()
        if not docs:
            return await callback.answer("У вас нет истории анализов.", show_alert=True)
        lines = []
        for doc in docs:
            snippet = doc.analysis.get("result", "")[:200].replace("\n", " ")
            lines.append(f"#{doc.id}: {snippet}...")
        text = "📜 История анализов:\n" + "\n".join(lines)
        await callback.message.answer(text)
EOF

echo "✅ main.py успешно обновлён: кнопка и handler истории анализов добавлены."
echo "▶️ Перезапустите бота: python main.py"

