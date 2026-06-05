# MCP Capture Tools

This folder contains the one-off scripts and artifacts used to inspect Stitch and capture reference material for the Flutter parent app.

## Scripts

- `call_fetch_mcp.js` - calls the patched MCP fetch flow and attempts to unzip a project export.
- `capture_stitch.js` - captures Stitch screenshots for the main project page.
- `capture_all_stitch.js` - attempts broader capture of Stitch-linked screens and assets.
- `capture_network.js` - logs network responses while browsing Stitch.
- `try_fetch_mcp.js` - probes available `@mintlify/mcp` installs and inspects exports.

## Artifacts

- `artifacts/network_log.jsonl` - captured network log output.
- `stitch_project_18040412930613593715.html` - captured Stitch HTML response used for reference.

## Notes

- These scripts depend on the local Node environment that includes Puppeteer and `@mintlify/mcp`.
- Paths are intentionally kept local to this repository so generated outputs stay out of the repo root.
- For app-facing reference images, see `parent_app/assets/snitch/`.
