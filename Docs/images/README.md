# Architecture infographic provenance

These illustrations were generated with the built-in image generation tool.
They depict the repository's Makefile and documentation, not new validation
results. Text equivalents remain beside each figure in the consuming pages.
Generated technology marks are illustrative, not official logo artwork.

Style reference: `indrajeetpatil.github.io/DESIGN.md` (Career Atlas), read on
2026-10-24: warm paper, ink serif headings, sans labels, restrained teal,
hairline rules, flat surfaces, and no shadows. Raster figures intentionally
retain their paper background in both GitHub themes.

## Accuracy checklist

- Inference stays on the default loopback endpoint; tool execution is in Copilot.
- CPU and GPU share unified memory; full GPU residency is not assumed.
- Initial downloads and approved tools can use the network.
- Derived model manifests reuse base weight blobs.
- `make verify` runs Copilot, then Ollama, then the final state check.
- The harness proves connectivity and basic tool execution, not general quality.

## Generation prompts

### local-inference.png

Scientific architecture infographic for GitHub documentation. Landscape 3:2, crisp legible typography and generous whitespace. Match Career Atlas DESIGN.md: warm paper #faf8f4, near-black ink #201d18, muted text #5d574c, hairline borders #e3ded2, sparse teal #14584d for arrows and meaningful emphasis. Fraunces-like serif title, Hanken Grotesk-like sans labels. Flat surfaces, tiny corner radii, no shadows, no gradients, no emoji, no decorative numbering. Use recognisable monochrome technology logos where appropriate plus restrained line icons. All labels must be accurate and legible. Title: 'Local coding inference'. Draw a large boundary 'Apple Silicon Mac'. Within it show Developer prompt → GitHub Copilot CLI (recognisable Copilot goggles icon) → Ollama (llama logo) → Qwen3.5 4B (model icon), with the model on shared CPU + GPU / unified memory. Label CLI-to-Ollama arrow 'Chat Completions · loopback HTTP' and endpoint '127.0.0.1:11434/v1'. Draw clearly directed return route from Qwen through Ollama to CLI labelled 'Response / proposed tool call'. A separate two-way branch from CLI to 'Project files' labelled 'Permission-controlled tools'. Below CLI label 'Terminal interaction'. A separate bottom note 'Initial installs and model downloads need internet'. Another note 'Approved tools may access the network'. Do not depict cloud inference, browser, dashboard or a database. Keep endpoint typography large.

### setup-stack.png

Scientific architecture infographic for GitHub documentation. Landscape 3:2, crisp legible typography and generous whitespace. Match Career Atlas DESIGN.md: warm paper #faf8f4, near-black ink #201d18, muted text #5d574c, hairline borders #e3ded2, sparse teal #14584d for arrows and meaningful emphasis. Fraunces-like serif title, Hanken Grotesk-like sans labels. Flat surfaces, tiny corner radii, no shadows, no gradients, no emoji, no decorative numbering. Use recognisable monochrome technology logos where appropriate plus restrained line icons. All labels must be accurate and legible. Title: 'Setup and technology stack'. Two stacked horizontal lanes. Upper lane title 'Preparation · make setup': 'Capacity checks' → 'Homebrew installs' → 'Ollama service' → 'Pull base model' → 'Configure derived model'. Under capacity 'Apple Silicon · RAM · disk'; under Homebrew show monochrome Homebrew mug and 'Copilot CLI · Ollama · jq'; under model pull 'qwen3.5:4b'; under derived model 'num_ctx = 32768'. Lower lane title 'Local state': Three separated storage objects with line icons: 'Model weights + manifests' with '~/.ollama/models/'; 'Isolated Copilot state' with '~/.copilot-local-offline/' and 'mode 0700'; 'Login service' with 'Homebrew LaunchAgent'. Show a thin connector from model stages to model storage, from Homebrew installs to isolated Copilot state, from Ollama service to Login service. Footer 'Derived model reuses the base weight blobs'. No databases, dashboards, browser frameworks, Docker or cloud runtime. Use wide boxes and concise text.

Final setup-stack generation added: IMPORTANT: Local state is an inventory, not a flow. Draw NO connectors or arrows between the preparation lane and the local state lane. Only connect the five preparation boxes left to right. Separate lanes with whitespace.

### quality-harness.png

Scientific architecture infographic for GitHub documentation. Landscape 3:2, crisp legible typography and generous whitespace. Match Career Atlas DESIGN.md: warm paper #faf8f4, near-black ink #201d18, muted text #5d574c, hairline borders #e3ded2, sparse teal #14584d for arrows and meaningful emphasis. Fraunces-like serif title, Hanken Grotesk-like sans labels. Flat surfaces, tiny corner radii, no shadows, no gradients, no emoji, no decorative numbering. Use recognisable monochrome technology logos where appropriate plus restrained line icons. All labels must be accurate and legible. Title: 'Local verification harness'. Top entry 'make verify'. A vertical ordered flow with TWO test panels then final state panel. First panel '1 · Copilot tool probe' with small Copilot logo: 'Fresh temporary directory' → 'Create probe.txt' → 'Check exact file bytes + final reply'. Beneath it 'Shell denied · only probe write allowed · normal tool definitions retained'. Small note 'Temporary directory cleaned on exit'. Arrow to second panel '2 · Ollama API probe' with llama icon: 'Chat Completions request' → 'Parse JSON with jq' → 'Check exact assistant content'. Arrow to third panel '3 · External state check': 'Tools · directory permissions · service · API · model · context'. Arrow to terminal 'Pass only when every check succeeds'. Footer note 'Connectivity and basic tool execution; not a benchmark or a network sandbox'. No parallel branching: tests run in the stated sequence. No performance scores, CI or claimed new results.
