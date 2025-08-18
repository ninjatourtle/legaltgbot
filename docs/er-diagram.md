# ER-диаграмма

Базовые сущности системы и их связи.

```mermaid
erDiagram
    USERS ||--o{ CHATS : participates_in
    CHATS ||--o{ MESSAGES : contains
    USERS ||--o{ MESSAGES : writes
```

## Описание сущностей

- **USERS** — пользователи Telegram.
- **CHATS** — чаты или каналы, в которых происходит общение.
- **MESSAGES** — сообщения, создаваемые пользователями в рамках чатов.
