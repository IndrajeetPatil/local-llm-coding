# Response workflow generation prompts

Built-in image generation; opaque paper background. Final asset:
`response-workflow.png`. Technology marks are generated illustrations.

## Initial generation

Use case: infographic-diagram
Asset type: scientific workflow infographic for repository documentation, landscape 3:2, high resolution, large readable labels.
Title verbatim: "How a local response becomes an action"
Style: Career Atlas design. Warm paper #faf8f4, ink #201d18 headings, muted ink #5d574c notes, hairline #e3ded2 rules, sparse teal #14584d arrows. Fraunces-like serif title and Hanken Grotesk-like sans labels. Flat precise technical illustration with ample whitespace, no shadows, gradients, glossy effects, invented numbering or decoration. Use monochrome Ollama llama and GitHub Copilot goggles marks beside their names, plus small chip, document, terminal and permission icons. Marks are illustrative.
Layout: clear top left-to-right response pipeline, with a lower tool loop. One thin enclosing boundary labelled "Apple Silicon Mac · default loopback inference".
Top row three stages:
"Qwen3.5" / "Generates text or a tool proposal" with CPU + GPU chip icon.
Arrow to "Ollama" / "OpenAI-compatible Chat Completions".
Arrow to "Copilot CLI" / "Assembles and interprets the response".
Under the Ollama-to-Copilot arrow label "HTTP · 127.0.0.1:11434" and "Streaming: SSE carrying JSON deltas".
Beneath the row an open hairline-ruled protocol strip titled "A shared message format". Two short lines verbatim "Stream: choices[0].delta" and "Non-stream: choices[0].message", and a small note "content = text · tool_calls = structured proposals". Do not draw raw JSON examples.
From Copilot branch to a right-hand terminal icon "Text content" → "Display in terminal".
From Copilot branch downward to "Structured tool call" → "Copilot permission check". From check arrow labelled "Allowed" to "Execute local tool" with file icon and small label "Read / edit project files". From check short separate branch labelled "Denied" to "No execution". From execute route a clearly arrowheaded return path labelled "Tool result → next request" back to Ollama (NOT to Qwen directly). Make this loop distinct and traceable and do not cross other arrows. Results and assistant tool calls are added to conversation for another inference turn.
Two short footer notes verbatim: "The model proposes; Copilot executes permitted tools." and "OpenAI-compatible describes the protocol, not a cloud destination."
Small bottom annotation "Plain text that looks like a tool call does not execute."
Accuracy constraints: no cloud icons, no network sandbox claim, no jq in the interactive pipeline. Show generation before API encoding. Tool loop repeats as needed before final reply. No implication every response executes a tool. All arrows must connect only their stated stages. Avoid excessive text, tiny type and decorative boxes.

## First correction

Edit the supplied scientific infographic. Preserve all text, typography, colours, icons and general layout. Correct ONLY the connectors: remove the curved connector that starts to the right of the permission shield, bends down, and enters Execute local tool from the right. Keep the vertical Allowed arrow from permission check down to Execute local tool. Keep a separate horizontal Denied arrow from permission check to No execution, with no connection to the Allowed path. Also move the shared message format strip slightly or reroute the return path so that the Tool result → next request return arrow runs continuously through whitespace rather than disappearing behind the shared message format strip. Route that return line along the left margin inside the Mac boundary if needed, ending with its arrowhead at Ollama. No other new arrows. The only flow from permission check is Allowed downward to execution or Denied rightward to no execution. Preserve the execution return path back to Ollama.

## Final correction

Correct this diagram's return connector only. Currently the bottom tool-result line ends at x104 y590 and a disconnected vertical line at x522 y490 goes to Ollama. Erase the entire bottom return connector AND the disconnected vertical teal line below Ollama. Replace them with ONE continuous teal connector: from Execute local tool at (1045,770) go down to (1045,825), left to (875,825), up to (875,325), left to (680,325), up to (680,285), ending with an arrowhead pointing up into Ollama's lower right. This route uses the empty vertical gutter between the message-format strip and the tool branch. Put the label 'Tool result → next request' along the bottom horizontal segment or nearby in the empty lower area. Do not let this connector touch or pass through the shared-message-format strip, whose right edge is x832. Preserve all other content including Allowed and Denied arrows. No extra arrows. Pixel coordinates refer to the supplied 1536x1024 image.
