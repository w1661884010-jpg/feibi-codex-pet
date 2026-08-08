"""Make Feibi's left-running row match the approved right-running cadence."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageOps


CELL_WIDTH = 192
CELL_HEIGHT = 208
COLUMNS = 8
ROWS = 11
RIGHT_ROW = 1
LEFT_ROW = 2


def cell_box(column: int, row: int) -> tuple[int, int, int, int]:
    return (
        column * CELL_WIDTH,
        row * CELL_HEIGHT,
        (column + 1) * CELL_WIDTH,
        (row + 1) * CELL_HEIGHT,
    )


def rebuild(source: Path, output: Path, preview: Path | None) -> None:
    with Image.open(source) as opened:
        atlas = opened.convert("RGBA")

    expected_size = (CELL_WIDTH * COLUMNS, CELL_HEIGHT * ROWS)
    if atlas.size != expected_size:
        raise ValueError(f"expected atlas {expected_size}, got {atlas.size}")

    left_frames: list[Image.Image] = []
    for column in range(COLUMNS):
        right_frame = atlas.crop(cell_box(column, RIGHT_ROW))
        left_frame = ImageOps.mirror(right_frame)
        atlas.paste(left_frame, cell_box(column, LEFT_ROW))
        left_frames.append(left_frame)

    # Clear invisible decoder residue so the v2 transparency contract remains exact.
    pixels = atlas.load()
    for y in range(atlas.height):
        for x in range(atlas.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha == 0 and (red or green or blue):
                pixels[x, y] = (0, 0, 0, 0)

    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output, "WEBP", lossless=True, quality=100, method=6, exact=True)

    if preview is not None:
        preview.parent.mkdir(parents=True, exist_ok=True)
        left_frames[0].save(
            preview,
            save_all=True,
            append_images=left_frames[1:],
            duration=120,
            loop=0,
            disposal=2,
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("atlas", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()
    rebuild(args.atlas, args.output, args.preview)


if __name__ == "__main__":
    main()
