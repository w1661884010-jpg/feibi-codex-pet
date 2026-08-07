"""Rebuild selected Feibi animation rows using only cells already in the atlas."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageOps


CELL_WIDTH = 192
CELL_HEIGHT = 208
COLUMNS = 8
ROWS = 11
RUNNING_RIGHT_ROW = 1
RUNNING_LEFT_ROW = 2
TASK_RUNNING_ROW = 7
TASK_RUNNING_FRAMES = 6


def cell_box(column: int, row: int) -> tuple[int, int, int, int]:
    return (
        column * CELL_WIDTH,
        row * CELL_HEIGHT,
        (column + 1) * CELL_WIDTH,
        (row + 1) * CELL_HEIGHT,
    )


def has_visible_pixels(image: Image.Image) -> bool:
    return image.getchannel("A").getbbox() is not None


def rebuild(source: Path, output: Path, task_preview: Path | None) -> None:
    with Image.open(source) as opened:
        atlas = opened.convert("RGBA")

    expected_size = (CELL_WIDTH * COLUMNS, CELL_HEIGHT * ROWS)
    if atlas.size != expected_size:
        raise ValueError(f"expected atlas {expected_size}, got {atlas.size}")

    original_task_frames = [
        atlas.crop(cell_box(column, TASK_RUNNING_ROW))
        for column in range(TASK_RUNNING_FRAMES)
    ]
    if not all(has_visible_pixels(frame) for frame in original_task_frames):
        raise ValueError("every active task-running frame must already be populated")

    for column in range(COLUMNS):
        right_frame = atlas.crop(cell_box(column, RUNNING_RIGHT_ROW))
        atlas.paste(ImageOps.mirror(right_frame), cell_box(column, RUNNING_LEFT_ROW))

    # Re-paste the approved existing laptop frames verbatim. This makes the
    # provenance explicit and guarantees that no synthesized art enters row 7.
    for column, frame in enumerate(original_task_frames):
        atlas.paste(frame, cell_box(column, TASK_RUNNING_ROW))

    # WebP decoders may expose stale RGB values beneath fully transparent
    # pixels. They are invisible but violate the v2 atlas packaging contract.
    pixels = atlas.load()
    for y in range(atlas.height):
        for x in range(atlas.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha == 0 and (red or green or blue):
                pixels[x, y] = (0, 0, 0, 0)

    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output, "WEBP", lossless=True, quality=100, method=6, exact=True)

    if task_preview is not None:
        task_preview.parent.mkdir(parents=True, exist_ok=True)
        original_task_frames[0].save(
            task_preview,
            save_all=True,
            append_images=original_task_frames[1:],
            duration=180,
            loop=0,
            disposal=2,
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("atlas", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--task-preview", type=Path)
    args = parser.parse_args()
    rebuild(args.atlas, args.output, args.task_preview)


if __name__ == "__main__":
    main()
