# Leafbound — дом Анзу (Godot 4.7)

Главное меню (YANGI HIKOYA / DAVOM ETISH / SOZLAMALAR / CHIQISH) → комната. Esc — пауза, сохранение.

Живая комната: Анзу ходит в 4 стороны и взаимодействует с предметами, печка горит и светит,
из чайника идёт пар, кот дышит и мурчит, в луче из окна летает пыль, после сна наступает вечер.

## Запуск

```bash
godot --path ~/Projects/Leafbound          # игра
godot -e --path ~/Projects/Leafbound       # редактор
```

WASD / стрелки — ходить, E / пробел / Enter — действие, F11 — полный экран
(на Hyprland окно тайлится и становится маленьким — жми F11).

## Что где

| Путь | Что это |
|---|---|
| `scenes/menu.tscn` | главное меню (собирает `tools/build_menu.gd`, координаты как в макете 1920×1080) |
| `art/menu/` | фон, кнопки (обычная/наведение/нажата/неактивна), лист логотипа, плашка — из макета `tools/menu_assets.py` |
| `scripts/settings.gd` | автозагрузка: клавиши, громкость, полный экран, музыка, сохранение |
| `scenes/main.tscn` | сцена комнаты (собирается скриптом, но открывается и правится в редакторе) |
| `scripts/` | `player.gd` ходьба и выбор предмета, `dialog.gd` окно текста, `cat.gd`, `stove.gd`, `main.gd` логика комнаты, день/вечер |
| `art/room_bg.png` | фон 256×256 (концепт из Gemini переведён в пиксели, объекты стёрты) |
| `art/ase/*.png` | кровать, кот, печка, стол — отрендерены из твоих `.aseprite` |
| `art/anzu_sheet_hd.png` | Анзу в родных 128×128 (оригинальный арт, показывается в масштабе 0.5): ряды down_idle, down_walk, up_idle, up_walk, side_idle, side_walk. Генерирует `tools/anzu_frames_hd.py` — только сдвигает твои пиксели (шаги, покачивание, взгляд), не перерисовывает |
| `art/cat_breath.png`, `art/stove_fire.png` | кадры дыхания кота и огня |
| `sfx/` | синтезированные звуки (огонь, мурчание, помехи радио, шаги, текст) |
| `audio/reiselust.ogg` | музыка (исходник был AAC с расширением .mp3 — Godot его не читает) |
| `tools/` | генераторы ассетов на Python и сборщик сцены |
| `source/` | исходные файлы из Telegram |

Тексты предметов — в `tools/build_scene.gd`, функция `_interactables()`.
Координаты везде в пикселях комнаты (фон 256×256).

## Профиль Анзу (ходьба вбок) — рисуешь сам

1. Открой `art/anzu_side.aseprite` в Aseprite: 6 кадров 128×128, теги `side_idle` (1–2) и `side_walk` (3–6).
   Слой **Guide** — полупрозрачная подложка (ноги уже в фазах шага), слой **Draw** — пустой, рисуй на нём профиль
   **лицом вправо** (влево игра отразит сама). Подошва — на строке 121, как у подложки.
   Нет Aseprite — есть `art/anzu_side_template.png` (те же 6 кадров в ряд).
2. Сохрани и пересобери:
   ```bash
   .venv/bin/python tools/anzu_frames_hd.py && godot --headless --path . --import
   ```
   Генератор сам возьмёт слой Draw (если во всех 6 кадрах что-то нарисовано), иначе оставит текущий поворот 3/4.

Сейчас профиль взят из картинок Gemini `source/gemini/side_stand.jpg` и `side_walk.jpg` (нарисованы на сетке 128,
`tools/gemini_side.py` снимает пиксели по центрам клеток, приводит к палитре Анзу, убирает фон и тень, отражает лицом
вправо и собирает шаг: шаг / стоя / шаг с ногами наоборот / стоя). Приоритет: слой Draw в `.aseprite` → Gemini → поворот 3/4.

Стоя на месте, Анзу через 0.35 с поворачивается к камере (`FACE_CAMERA_AFTER` в `scripts/player.gd`).

## Пересборка

```bash
cd ~/Projects/Leafbound
.venv/bin/python tools/build_room.py      # фон
.venv/bin/python tools/anzu_frames_hd.py  # кадры Анзу (128 px, из Anzu.png)
.venv/bin/python tools/prop_frames.py     # кот, огонь, частицы
.venv/bin/python tools/make_misc.py       # тень, кнопка E, звуки
godot --headless --path . --import
godot --headless --path . -s res://tools/build_scene.gd
godot --headless --path . -s res://tools/build_menu.gd
```

## Сборка для друга (Linux)

```bash
godot --headless --path . --export-pack "Linux" build/Leafbound.pck
# dist/Leafbound/ = Godot 4.7.2 (переименован в Leafbound.x86_64) + Leafbound.pck + play.sh + README.txt
cp build/Leafbound.pck dist/Leafbound/ && (cd dist && zip -qr9 Leafbound-linux.zip Leafbound)
```

Windows: тот же `Leafbound.pck` + официальный `Godot_v4.7.2-stable_win64.exe`, переименованный в `Leafbound.exe`
(`dist/Leafbound-windows/`, архив `Leafbound-windows.zip`). Экспорт-шаблоны не нужны.

Бинарник рядом с одноимённым `.pck` сразу запускает игру. Рендер — Compatibility (OpenGL 3.3), чтобы шло на слабом железе.
Реплики предметов хранятся строкой с переносами (`text`), а не PackedStringArray: в Godot 4.7 массив терялся при экспорте.

Правки, сделанные руками в редакторе в `main.tscn`, затрутся при пересборке —
либо правь `build_scene.gd`, либо больше не запускай сборщик.

`.aseprite` без Aseprite: `.venv/bin/python tools/ase_dump.py file.aseprite out_dir`.

## Автотест

```bash
LB_AUTOTEST=/tmp/lb godot --path .              # сам ходит, гладит кота, спит, сохраняет снимки
LB_AUTOTEST=/tmp/lb LB_RECORD=1 godot --path . --fixed-fps 30   # + каждый кадр для видео
```

## Что улучшить дальше

- Вид сбоку у Анзу — поворот на 3/4 из фронтального спрайта, не настоящий профиль.
  Лучше перерисовать в Aseprite по `art/anzu_sheet.png` (ряды 4–5).
- Полка, дверь, радио, окно, шарф — пока часть фона; можно перерисовать отдельными спрайтами.
