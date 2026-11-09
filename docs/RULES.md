# Rules for working in this repository (read first)

1. **Releases, tags and pushes to GitHub only after the user says yes.** Build locally, show what changed, wait.
2. **Be brief.** Short answers. No long reports unless asked.
3. **Never run diagnostics inside a game callback.** File-gated only, bounded, outside `Multicast_*` / observers.
4. **Do not touch UI** (widgets, input mode, focus) without permission.
5. **One change - one check.** Verify nothing broke before the next step.
6. **When in doubt, roll back** instead of trying another variant.
7. **Never suggest taking a break.** Work continues until the user says stop.
8. **Отвечай по-русски.** Все ответы, отчёты и объяснения в чате — на русском языке (код, логи и файлы остаются как есть).
9. **Каждую полезную функцию — в notes и в репозиторий.** Любой рабочий способ заспавнить предмет, выдать предмет, телепортировать актора, перевести время суток, убить героя, дернуть функцию движка (`probe`, `call`, `spawn`, консоль) — всё, что может понадобиться больше одного раза при тестировании или прохождении, — сразу пишется в реестр вызовов в `docs/NOTES.md`, коммитится и пушится. Даже мелочь: потом не нужно искать заново правильный спавн руды. Формат записи: что делает, точная команда, дата проверки, где проверено. Исключение из пункта 1: записи этого реестра можно пушить без отдельного разрешения.
