# 088-answer-page-open-questions-tall

## What made it
- scripts/answer-server running; scripts/generate-answer-pages (photographed: headless Firefox, 1400x30000, http://127.0.0.1:8642/answer-pages/open-questions.html)
- Commit: f0577e0
- Filed: 2026-10-29 22:44 by scripts/file-screenshot

| Source | Fingerprint (BLAKE2b, first 16) |
|---|---|
| `scripts/generate-answer-pages` | 2af309a7dc28c73d |
| `scripts/answer-server` | 3faa29cbe43a5b7c |
| `docs/answer-pages/open-questions.md` | 1b6ff134e8264b8f |

## What changed since the previous picture
- `scripts/generate-answer-pages`: unchanged since 087-answer-page-alterac-weather
- `scripts/answer-server`: unchanged since 087-answer-page-alterac-weather
- `docs/answer-pages/open-questions.md`: unchanged since 083-answer-page-open-questions

## What it shows
Every Open Question, the top 30,000 pixels at full resolution (the whole page, with about a thousand open questions, is beyond what Firefox will photograph in one picture): the story with its five gifs (dark: a still catches each gif's first frame), the filters (ring, state, phase, sort, search, show answered), the count, then the issues in order of how many open issues wait on them, 617 (the buddy bots, 125 waiting) first, each question with its answer box and Send button.

## The story so far
The five architecture pages you can answer on were built and committed (f0577e013), then photographed again at the owner's word, "Make sure you take full resolution screenshots": whole pages at full resolution this time, where 083-087 showed only each page's top 2,400 pixels.
