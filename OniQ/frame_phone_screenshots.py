"""Wrap raw screen captures from updates/ in a phone mockup frame.

Output: updates/framed/<n>.png  (RGBA, transparent corners)

Each output is the original screenshot composited inside a black phone body
with rounded corners that match — so the result reads like a real phone
display, not an image stuffed into a case.
"""

from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path

SRC_DIR = Path("C:/Users/12345/Desktop/Projects/OnionGuard/updates")
OUT_DIR = SRC_DIR / "framed"
OUT_DIR.mkdir(exist_ok=True)

# Phone styling (relative to the screenshot's smaller dimension)
BEZEL_RATIO = 0.045          # bezel thickness as fraction of width
SCREEN_CORNER_RATIO = 0.06   # rounded corners on the screen (matching modern Android)
BODY_CORNER_RATIO = 0.085    # outer phone-body corners (slightly larger)
NOTCH_W_RATIO = 0.32         # dynamic-island width as fraction of phone width
NOTCH_H_RATIO = 0.022        # notch height as fraction of phone height
SHADOW_OFFSET = 14           # drop shadow offset in pixels at 1080-wide
SHADOW_BLUR = 30
BODY_COLOR = (18, 18, 20, 255)
NOTCH_COLOR = (5, 5, 5, 255)


def round_corners(img: Image.Image, radius: int) -> Image.Image:
    """Return an RGBA copy of img with corners outside `radius` made transparent."""
    img = img.convert("RGBA")
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, img.size[0], img.size[1]), radius=radius, fill=255
    )
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def make_phone_mockup(src_path: Path, dst_path: Path) -> None:
    screen = Image.open(src_path).convert("RGB")
    sw, sh = screen.size  # screen pixel size

    # Compute bezel and overall body size
    bezel = max(2, int(sw * BEZEL_RATIO))
    body_w = sw + 2 * bezel
    body_h = sh + 2 * bezel

    # Round the screen corners (so they hug the body's inner curve)
    screen_radius = max(2, int(sw * SCREEN_CORNER_RATIO))
    rounded_screen = round_corners(screen, screen_radius)

    # Build the phone body (rounded rect, transparent corners, dark fill)
    body = Image.new("RGBA", (body_w, body_h), (0, 0, 0, 0))
    body_draw = ImageDraw.Draw(body)
    body_radius = max(2, int(sw * BODY_CORNER_RATIO))
    body_draw.rounded_rectangle(
        (0, 0, body_w, body_h),
        radius=body_radius,
        fill=BODY_COLOR,
    )

    # Paste the rounded screen into the body, inset by the bezel.
    body.alpha_composite(rounded_screen, dest=(bezel, bezel))

    # Dynamic-island / notch pill at the top of the bezel
    notch_w = int(body_w * NOTCH_W_RATIO)
    notch_h = max(6, int(body_h * NOTCH_H_RATIO))
    notch_y = max(2, (bezel - notch_h) // 2)
    notch_x = (body_w - notch_w) // 2
    body_draw.rounded_rectangle(
        (notch_x, notch_y, notch_x + notch_w, notch_y + notch_h),
        radius=notch_h // 2,
        fill=NOTCH_COLOR,
    )

    # Add a soft drop shadow on a transparent canvas slightly larger than the body
    pad = SHADOW_BLUR + SHADOW_OFFSET
    canvas = Image.new("RGBA", (body_w + 2 * pad, body_h + 2 * pad), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (pad, pad + SHADOW_OFFSET // 2,
         pad + body_w, pad + body_h + SHADOW_OFFSET // 2),
        radius=body_radius, fill=(0, 0, 0, 100),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(SHADOW_BLUR))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(body, dest=(pad, pad))

    canvas.save(dst_path, format="PNG")
    print(f"  {src_path.name} -> {dst_path.name}  ({canvas.size[0]}x{canvas.size[1]})")


def main():
    sources = sorted(SRC_DIR.glob("*.jpeg"))
    if not sources:
        print("No .jpeg sources found.")
        return
    print(f"Framing {len(sources)} screenshots into phone mockups...")
    for src in sources:
        dst = OUT_DIR / (src.stem + ".png")
        make_phone_mockup(src, dst)
    print(f"\nDone. Output in: {OUT_DIR}")


if __name__ == "__main__":
    main()
