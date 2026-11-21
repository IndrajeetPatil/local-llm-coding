library(magick)

# The GitHub social preview card (Settings > General > Social preview):
# 1280 x 640 on paper, with the hex sticker on the right and the title,
# tagline, and URL on the left. Run hextools/script.R first so the sticker is
# current. Needs the Fraunces and Hanken Grotesk fonts installed.

width <- 1280
height <- 640
margin <- 96

bg <- "#faf8f4"
text <- "#201d18"
text_muted <- "#5d574c"
accent <- "#14584d"
border <- "#e3ded2"

logo <- image_read("docs/images/logo.png") |>
    image_resize("x440")

card <- image_blank(width, height, color = bg) |>
    image_composite(
        logo,
        offset = sprintf(
            "+%d+%d",
            width - margin - image_info(logo)$width,
            (height - image_info(logo)$height) %/% 2
        )
    ) |>
    image_annotate(
        "local-llm-coding",
        font = "Fraunces",
        weight = 600,
        size = 76,
        color = text,
        location = sprintf("+%d+%d", margin, 186)
    ) |>
    image_annotate(
        "Coding with local LLMs.\nOffline, on your Apple Silicon Mac.",
        font = "Hanken Grotesk",
        weight = 400,
        size = 38,
        color = text_muted,
        location = sprintf("+%d+%d", margin, 306)
    ) |>
    image_annotate(
        "github.com/IndrajeetPatil/local-llm-coding",
        font = "Hanken Grotesk",
        weight = 600,
        size = 26,
        color = accent,
        location = sprintf("+%d+%d", margin, 470)
    )

# Hairline accent rule under the title, and a hairline frame.
card <- image_draw(card)
rect(margin, 286, margin + 72, 290, col = accent, border = NA)
rect(0.5, 0.5, width - 0.5, height - 0.5, border = border, lwd = 2)
dev.off()

image_write(card, "docs/images/social-card.png", format = "png", depth = 8)
