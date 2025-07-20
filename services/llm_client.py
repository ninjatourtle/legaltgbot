import asyncio
from openai import OpenAI
from config import settings

client = OpenAI(api_key=settings.OPENAI_API_KEY)

def _sync_analyze(text: str) -> str:
    prompt = (
        "Ты — эксперт по юридическому анализу контрактов. "
        "Проанализируй текст, выдели ключевые риски, предложи улучшения и дай краткий обзор:\\n\\n"
        f"{text}"
    )
    completion = client.chat.completions.create(
        model="chatgpt-4o-latest",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.2,
    )
    return completion.choices[0].message.content

async def analyze_contract(text: str) -> str:
    return await asyncio.to_thread(_sync_analyze, text)
