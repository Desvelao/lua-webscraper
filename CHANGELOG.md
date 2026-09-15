# Changelog

All notable changes to this project are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] - 2026-09-15

### Added
- Computed and temporal properties: a field can derive its value from other fields via `compute`, a small arithmetic expression (`+ - * /`, parentheses, unary minus) resolved by field name, in dependency order; `temporal` fields are extracted/computed normally but stripped from the final result.
- `attr(name)` filter: reads an HTML attribute (e.g. `href`, `src`) off the matched element.
- `text` filter: extracts the matched element's text/inner content — the pipeline's previous implicit default, now available as an explicit step.
- `to_negate` filter: inverts a boolean value.
- Page validation: an optional `page` config (`block_selector`, `block_text`, `expect_selector`) is checked right after the page is fetched and parsed, before any field is extracted — catches a bot-check/CAPTCHA page that responds 200 with unrelated content instead of silently producing empty fields.
- Configurable request headers via `WebScraper:new({ user_agent, headers })`, merged on top of a new default header set (which now also includes a real browser `User-Agent`, previously absent entirely).
- GitHub Actions: a `luarocks` job in `.github/workflows/publish.yml` uploads the package to LuaRocks on every `v*` tag push, alongside the existing LDoc → GitHub Pages `docs` job.

### Changed
- A field's `transform` pipeline is now seeded with the matched element itself instead of its pre-extracted text — start a transform with `text` to get the previous default behavior back, or use `attr(name)` to read an attribute directly. A field with no `transform` at all still defaults to the element's text content, unchanged.
- `WebScraper:run()` / `WebScraper:_run()` now return `result, err` (`err` is non-nil on a failed fetch or a `page` validation failure) instead of just `result`.
- Renamed the `docs` GitHub Actions workflow to `publish` (`.github/workflows/docs.yml` → `.github/workflows/publish.yml`).

### Removed
- `WebScraper:load_from_remote(url)` — unused method for fetching site definitions from a remote JSON endpoint.

## [0.1.0] - 2025-09-29

### Added
- Initial release: site registration with URL matchers and CSS-selector-based field extraction, filter/validator pipelines, and custom filter/validator registration.
- Built-in filters: `lowercase`, `match`, `parse_date`, `replace`, `to_boolean`, `to_number`, `trim`, `uppercase`.
- Built-in validators: `is_boolean`, `is_number`, `is_string`.
