"""Generate OnionGuard Update Release slide deck (v1.2.0).

Mirrors the design system from generate_pptx.py:
- 16:9 layout, 13.333 x 7.5 inches
- Green palette (#4CAF50 primary), Calibri typography
- Green header bar with white title + light-green subtitle
- Same helper functions and colour tokens
"""

from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE
import os

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)

# Colors — matching generate_pptx.py exactly
GREEN = RGBColor(76, 175, 80)
DARK_GREEN = RGBColor(46, 125, 50)
WHITE = RGBColor(255, 255, 255)
DARK = RGBColor(33, 33, 33)
GRAY = RGBColor(100, 100, 100)
LIGHT_BG = RGBColor(245, 245, 245)
ACCENT_BLUE = RGBColor(21, 101, 192)
ACCENT_ORANGE = RGBColor(230, 115, 0)
ACCENT_RED = RGBColor(211, 47, 47)
LIGHT_GREEN_BG = RGBColor(232, 245, 233)
SUBTITLE_GREEN = RGBColor(200, 255, 200)
SOFT_GREEN = RGBColor(180, 230, 180)

ONION_IMG = "C:/Users/12345/Desktop/Projects/OnionGuard/onion-guard-mobile/frontend/assets/onion-image.jpg"
UPDATES_DIR = "C:/Users/12345/Desktop/Projects/OnionGuard/updates/"
FRAMED_DIR = "C:/Users/12345/Desktop/Projects/OnionGuard/updates/framed/"


# ── Helpers ──────────────────────────────────────────────────────────────────

def add_bg(slide, color):
    fill = slide.background.fill
    fill.solid()
    fill.fore_color.rgb = color


def add_shape_bg(slide, left, top, width, height, color):
    shape = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, left, top, width, height)
    shape.fill.solid()
    shape.fill.fore_color.rgb = color
    shape.line.fill.background()
    return shape


def add_text_box(slide, left, top, width, height, text, font_size=18, bold=False,
                 color=DARK, alignment=PP_ALIGN.LEFT, font_name='Calibri'):
    tx = slide.shapes.add_textbox(left, top, width, height)
    tf = tx.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = text
    p.font.size = Pt(font_size)
    p.font.bold = bold
    p.font.color.rgb = color
    p.font.name = font_name
    p.alignment = alignment
    return tx


def add_bullet_list(slide, left, top, width, height, items, font_size=16,
                    color=DARK, spacing=Pt(8), bullet_char='•  '):
    tx = slide.shapes.add_textbox(left, top, width, height)
    tf = tx.text_frame
    tf.word_wrap = True
    for i, item in enumerate(items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.text = bullet_char + item
        p.font.size = Pt(font_size)
        p.font.color.rgb = color
        p.font.name = 'Calibri'
        p.space_after = spacing
    return tx


def slide_header(slide, title, subtitle=None):
    add_shape_bg(slide, Inches(0), Inches(0), prs.slide_width, Inches(1.2), GREEN)
    add_text_box(slide, Inches(0.8), Inches(0.25), Inches(11.5), Inches(0.7),
                 title, font_size=32, bold=True, color=WHITE)
    if subtitle:
        add_text_box(slide, Inches(0.8), Inches(0.78), Inches(11.5), Inches(0.4),
                     subtitle, font_size=16, color=SUBTITLE_GREEN)


def add_pill(slide, left, top, width, height, text, fill_color, text_color=WHITE,
             font_size=14, bold=True):
    shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, left, top, width, height)
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill_color
    shape.line.fill.background()
    tf = shape.text_frame
    tf.margin_left = Inches(0.15)
    tf.margin_right = Inches(0.15)
    tf.margin_top = Inches(0.05)
    tf.margin_bottom = Inches(0.05)
    p = tf.paragraphs[0]
    p.text = text
    p.font.size = Pt(font_size)
    p.font.bold = bold
    p.font.color.rgb = text_color
    p.font.name = 'Calibri'
    p.alignment = PP_ALIGN.CENTER
    return shape


def add_phone_tile(slide, image_path, label, left, top, card_w, card_h,
                    phone_w, phone_h, card_color=None):
    """Draw a soft-tinted card with a phone screenshot centered inside it
    and a caption at the bottom — matching the visual rhythm of the
    progress-report screenshot slides.
    """
    if card_color is None:
        card_color = LIGHT_GREEN_BG
    # Background card (rounded rectangle, light tint, no border)
    card = slide.shapes.add_shape(
        MSO_SHAPE.ROUNDED_RECTANGLE, left, top, card_w, card_h,
    )
    card.fill.solid()
    card.fill.fore_color.rgb = card_color
    card.line.fill.background()
    try:
        card.adjustments[0] = 0.05  # gentle corner rounding
    except Exception:
        pass

    # Phone image — horizontally centered in the card, small top inset.
    phone_x = left + (card_w - phone_w) / 2
    phone_y = top + Inches(0.22)
    if os.path.exists(image_path):
        slide.shapes.add_picture(image_path, phone_x, phone_y, phone_w, phone_h)

    # Caption pinned near the bottom of the card.
    caption_y = top + card_h - Inches(0.55)
    add_text_box(slide, left, caption_y, card_w, Inches(0.4), label,
                 font_size=14, bold=True, color=DARK_GREEN,
                 alignment=PP_ALIGN.CENTER)


def add_phone_screenshot(slide, path, left, top, width, height,
                          bezel=Inches(0.09),
                          bezel_color=RGBColor(30, 30, 30)):
    """Place a screenshot inside a dark rounded-rectangle 'phone case' bezel
    so a raw screen capture reads like a phone mock-up. The bezel is drawn
    first (behind), the image is then placed on top, fully covering the
    inner area so the bezel only shows as a frame around the screen.
    """
    if not os.path.exists(path):
        return
    # Phone body — dark rounded rect, slightly larger than the screenshot.
    body = slide.shapes.add_shape(
        MSO_SHAPE.ROUNDED_RECTANGLE,
        left - bezel, top - bezel,
        width + 2 * bezel, height + 2 * bezel,
    )
    body.fill.solid()
    body.fill.fore_color.rgb = bezel_color
    body.line.fill.background()
    # Adjust corner radius (the default is aggressive, scale it down a touch).
    try:
        body.adjustments[0] = 0.10
    except Exception:
        pass
    # Optional: subtle dynamic-island / notch pill at the top of the bezel.
    notch_w = width * 0.22
    notch_h = bezel * 0.9
    notch = slide.shapes.add_shape(
        MSO_SHAPE.ROUNDED_RECTANGLE,
        left + (width - notch_w) / 2,
        top - bezel + (bezel - notch_h) / 2,
        notch_w, notch_h,
    )
    notch.fill.solid()
    notch.fill.fore_color.rgb = RGBColor(15, 15, 15)
    notch.line.fill.background()
    try:
        notch.adjustments[0] = 0.5
    except Exception:
        pass
    # The screenshot itself sits flush inside the bezel.
    slide.shapes.add_picture(path, left, top, width, height)


def add_card(slide, left, top, width, height, title, body_lines,
             title_color=DARK_GREEN, accent=GREEN):
    add_shape_bg(slide, left, top, width, height, LIGHT_GREEN_BG)
    # accent stripe on the left
    add_shape_bg(slide, left, top, Inches(0.12), height, accent)
    add_text_box(slide, left + Inches(0.35), top + Inches(0.18),
                 width - Inches(0.5), Inches(0.5),
                 title, font_size=18, bold=True, color=title_color)
    add_bullet_list(slide, left + Inches(0.35), top + Inches(0.78),
                    width - Inches(0.5), height - Inches(0.85),
                    body_lines, font_size=13, color=DARK, spacing=Pt(4))


# ============================================================
# SLIDE 1: TITLE
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, DARK_GREEN)
add_shape_bg(slide, Inches(0), Inches(0), prs.slide_width, prs.slide_height,
             RGBColor(38, 120, 45))

if os.path.exists(ONION_IMG):
    slide.shapes.add_picture(ONION_IMG, Inches(9.8), Inches(0.7), Inches(2.8), Inches(2.8))

add_text_box(slide, Inches(1), Inches(0.9), Inches(9), Inches(0.7),
             'OnionGuard', font_size=44, bold=True, color=WHITE)
add_text_box(slide, Inches(1), Inches(1.85), Inches(9), Inches(0.6),
             'Update Release Report', font_size=26, color=SUBTITLE_GREEN)

# Big version banner
add_shape_bg(slide, Inches(1), Inches(2.9), Inches(5.5), Inches(1.4),
             RGBColor(255, 255, 255))
add_text_box(slide, Inches(1.3), Inches(3.05), Inches(5.2), Inches(0.5),
             'Version 1.2.0  ·  Build 9', font_size=24, bold=True, color=DARK_GREEN)
add_text_box(slide, Inches(1.3), Inches(3.55), Inches(5.2), Inches(0.6),
             'Released: April 29, 2026', font_size=16, color=GRAY)

# Live pill
add_pill(slide, Inches(1), Inches(4.6), Inches(4), Inches(0.6),
         'NOW LIVE ON GOOGLE PLAY STORE', RGBColor(40, 167, 69),
         font_size=16, bold=True)

# Divider line
add_shape_bg(slide, Inches(1), Inches(5.5), Inches(3), Pt(3), WHITE)

add_text_box(slide, Inches(1), Inches(5.7), Inches(11), Inches(0.5),
             'Apr 28 – Apr 29, 2026', font_size=18, color=WHITE)
add_text_box(slide, Inches(1), Inches(6.2), Inches(11), Inches(0.5),
             'Nkabom Honours Team  ·  University of Ghana',
             font_size=14, color=SOFT_GREEN)


# ============================================================
# SLIDE 2: WHAT'S NEW – OVERVIEW
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, WHITE)
slide_header(slide, "What's New in This Release",
             "Four updates shipping in version 1.2.0")

# Big headline strip
add_shape_bg(slide, Inches(0.6), Inches(1.6), Inches(12.1), Inches(1.0),
             LIGHT_GREEN_BG)
add_text_box(slide, Inches(0.85), Inches(1.75), Inches(11.6), Inches(0.5),
             'Headline: farmers can now correct the AI when it gets things wrong',
             font_size=20, bold=True, color=DARK_GREEN)
add_text_box(slide, Inches(0.85), Inches(2.18), Inches(11.6), Inches(0.4),
             'A human-in-the-loop correction system — every correction makes the next model smarter.',
             font_size=14, color=GRAY)

# 2x2 grid of cards
card_w = Inches(5.95)
card_h = Inches(1.95)
left1, left2 = Inches(0.6), Inches(6.78)
top1, top2 = Inches(2.95), Inches(5.0)

add_card(slide, left1, top1, card_w, card_h,
         '1.  Scan Correction & Review System',
         ['"Review this" button on every scan result',
          'Dropdown for correct class + optional comment',
          'Admin queue with one-click ZIP export (CSV + images)'])

add_card(slide, left2, top1, card_w, card_h,
         '2.  Smarter Scan Pre-Check',
         ['Model now rejects non-onion images before classifying',
          'Removes confidently-wrong predictions on hands, tomatoes, etc.',
          'Higher trust in every disease result'])

add_card(slide, left1, top2, card_w, card_h,
         '3.  Fingerprint Login Fixed',
         ['Was completely broken — tap did nothing',
          'Now: fingerprint match opens the app instantly',
          'No password retyping, even after logout'],
         accent=ACCENT_ORANGE)

add_card(slide, left2, top2, card_w, card_h,
         '4.  Analytics & Language Support',
         ['Smoother spline-curve time-series chart',
          '+2 new languages: Kusaal, Gurene (Frafra)',
          'Total supported languages: 9'],
         accent=ACCENT_BLUE)


# ============================================================
# SLIDE 3: HEADLINE FEATURE — REVIEW SYSTEM
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, WHITE)
slide_header(slide, "Headline: Scan Correction & Review",
             "Closing the loop between users and the AI model")

add_text_box(slide, Inches(0.7), Inches(1.5), Inches(12), Inches(0.5),
             'Why this matters',
             font_size=20, bold=True, color=DARK_GREEN)
add_text_box(slide, Inches(0.7), Inches(2.0), Inches(12), Inches(1.0),
             'Until now, when the AI got a diagnosis wrong, that mistake was invisible. '
             'Now every wrong prediction can be flagged with the correct answer — turning errors '
             'into training data and creating a feedback loop that compounds with usage.',
             font_size=14, color=DARK)

# How it works pills
add_text_box(slide, Inches(0.7), Inches(3.15), Inches(12), Inches(0.5),
             'How it works (user flow)', font_size=20, bold=True, color=DARK_GREEN)

steps = [
    ('1', 'User scans an onion'),
    ('2', 'Sees the AI prediction'),
    ('3', 'Taps "Review this" if wrong'),
    ('4', 'Picks correct class + comment'),
    ('5', 'Saved to admin queue'),
]
step_w = Inches(2.3)
gap = Inches(0.18)
left = Inches(0.7)
for num, label in steps:
    add_shape_bg(slide, left, Inches(3.7), step_w, Inches(0.95), LIGHT_GREEN_BG)
    add_shape_bg(slide, left, Inches(3.7), Inches(0.55), Inches(0.95), GREEN)
    add_text_box(slide, left, Inches(3.85), Inches(0.55), Inches(0.6), num,
                 font_size=24, bold=True, color=WHITE, alignment=PP_ALIGN.CENTER)
    add_text_box(slide, left + Inches(0.65), Inches(3.95), step_w - Inches(0.7),
                 Inches(0.7), label, font_size=12, color=DARK)
    left += step_w + gap

# Permissions / Admin perks
add_text_box(slide, Inches(0.7), Inches(4.95), Inches(12), Inches(0.5),
             'Roles & access', font_size=20, bold=True, color=DARK_GREEN)
add_bullet_list(slide, Inches(0.9), Inches(5.45), Inches(11.5), Inches(2.0),
                ['Farmers & Extension Officers — see only their own corrections (Settings → My Reviews)',
                 'Admins — see the full queue across all users, plus one-click ZIP export',
                 'Export bundle is ML-ready: reviews.csv (metadata) + images/<id>.jpg (training samples)',
                 'CSV columns: id, image path, user, role, original prediction, corrected label, comment, timestamps'],
                font_size=14, color=DARK, spacing=Pt(8))


# ============================================================
# SLIDE 4: AI RELIABILITY — NON-ONION REJECTION
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, WHITE)
slide_header(slide, "Improved AI Scan Reliability",
             "Catching obvious non-onion images before classification")

# Before / After comparison
col_w = Inches(5.85)
col_top = Inches(1.6)
col_h = Inches(5.4)

# BEFORE
add_shape_bg(slide, Inches(0.7), col_top, col_w, col_h, RGBColor(253, 237, 237))
add_shape_bg(slide, Inches(0.7), col_top, col_w, Inches(0.7), ACCENT_RED)
add_text_box(slide, Inches(0.95), col_top + Inches(0.15), col_w - Inches(0.5),
             Inches(0.5), 'BEFORE', font_size=18, bold=True, color=WHITE)
add_bullet_list(slide, Inches(0.95), col_top + Inches(1.0),
                col_w - Inches(0.5), col_h - Inches(1.1),
                ['User accidentally scans a hand, tomato, or coin',
                 'Model confidently labels it as "Fusarium 87%"',
                 'Farmer trusts the wrong diagnosis',
                 'False-positive disease counts pollute analytics',
                 'Trust in the app erodes'],
                font_size=14, color=DARK, spacing=Pt(10))

# AFTER
left2 = Inches(6.78)
add_shape_bg(slide, left2, col_top, col_w, col_h, LIGHT_GREEN_BG)
add_shape_bg(slide, left2, col_top, col_w, Inches(0.7), GREEN)
add_text_box(slide, left2 + Inches(0.25), col_top + Inches(0.15), col_w - Inches(0.5),
             Inches(0.5), 'AFTER', font_size=18, bold=True, color=WHITE)
add_bullet_list(slide, left2 + Inches(0.25), col_top + Inches(1.0),
                col_w - Inches(0.5), col_h - Inches(1.1),
                ['Pre-check rejects non-onion images',
                 'User gets clear "Please scan an onion" message',
                 'Disease classifier only runs on real onion images',
                 'Cleaner analytics, more reliable disease counts',
                 'Stronger user trust in every result'],
                font_size=14, color=DARK, spacing=Pt(10))


# ============================================================
# SLIDE 5: FINGERPRINT LOGIN FIX
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, WHITE)
slide_header(slide, "Fixed: Fingerprint Login",
             "From completely broken to instant entry")

# What was happening
add_shape_bg(slide, Inches(0.7), Inches(1.6), Inches(12), Inches(1.5),
             RGBColor(253, 237, 237))
add_shape_bg(slide, Inches(0.7), Inches(1.6), Inches(0.15), Inches(1.5), ACCENT_RED)
add_text_box(slide, Inches(1.0), Inches(1.75), Inches(11.5), Inches(0.5),
             'What was broken', font_size=18, bold=True, color=ACCENT_RED)
add_text_box(slide, Inches(1.0), Inches(2.2), Inches(11.5), Inches(0.9),
             'Tapping "Login with Biometrics" did nothing — no prompt appeared, no error shown. '
             'A complete user-facing failure that affected every user with biometrics enabled.',
             font_size=14, color=DARK)

# What we fixed
add_shape_bg(slide, Inches(0.7), Inches(3.3), Inches(12), Inches(2.0),
             LIGHT_GREEN_BG)
add_shape_bg(slide, Inches(0.7), Inches(3.3), Inches(0.15), Inches(2.0), GREEN)
add_text_box(slide, Inches(1.0), Inches(3.45), Inches(11.5), Inches(0.5),
             'What we fixed', font_size=18, bold=True, color=DARK_GREEN)
add_bullet_list(slide, Inches(1.0), Inches(3.95), Inches(11.5), Inches(1.4),
                ['Three Android-side configuration bugs traced & corrected',
                 'Errors no longer swallowed silently — users see clear messages on failure',
                 'Removed the requirement to retype the password before each biometric login'],
                font_size=14, color=DARK, spacing=Pt(8))

# Net result
add_text_box(slide, Inches(0.7), Inches(5.55), Inches(12), Inches(0.5),
             'Net result for users', font_size=20, bold=True, color=DARK_GREEN)
add_text_box(slide, Inches(0.7), Inches(6.05), Inches(12), Inches(1.2),
             'Open the app → tap fingerprint → in. Even after logout. '
             'A daily friction point removed for every active user.',
             font_size=16, color=DARK)


# ============================================================
# SLIDE 6: ANALYTICS & LANGUAGES
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, WHITE)
slide_header(slide, "Analytics & Language Support",
             "Smoother charts and broader linguistic reach")

# Two columns
col_top = Inches(1.6)
col_h = Inches(5.4)
col_w = Inches(5.85)

# LEFT: Analytics
add_shape_bg(slide, Inches(0.7), col_top, col_w, col_h, LIGHT_GREEN_BG)
add_shape_bg(slide, Inches(0.7), col_top, col_w, Inches(0.7), ACCENT_BLUE)
add_text_box(slide, Inches(0.95), col_top + Inches(0.15), col_w - Inches(0.5),
             Inches(0.5), 'ANALYTICS', font_size=18, bold=True, color=WHITE)
add_bullet_list(slide, Inches(0.95), col_top + Inches(1.0),
                col_w - Inches(0.5), col_h - Inches(1.1),
                ['Time-series chart upgraded to spline curves — smoother, more readable',
                 'Regional analytics fully localized into all supported languages',
                 'Disease-trend visualisations now consistent across the app'],
                font_size=14, color=DARK, spacing=Pt(10))

# RIGHT: Languages
left2 = Inches(6.78)
add_shape_bg(slide, left2, col_top, col_w, col_h, LIGHT_GREEN_BG)
add_shape_bg(slide, left2, col_top, col_w, Inches(0.7), GREEN)
add_text_box(slide, left2 + Inches(0.25), col_top + Inches(0.15), col_w - Inches(0.5),
             Inches(0.5), 'LANGUAGES  (7 → 9)', font_size=18, bold=True, color=WHITE)
add_text_box(slide, left2 + Inches(0.25), col_top + Inches(1.0), col_w - Inches(0.5),
             Inches(0.4), 'Existing (7):', font_size=13, bold=True, color=DARK_GREEN)
add_text_box(slide, left2 + Inches(0.25), col_top + Inches(1.4), col_w - Inches(0.5),
             Inches(0.5), 'English · Twi · Dagbani · Ewe · Hausa · Mampruli · French',
             font_size=13, color=DARK)
add_text_box(slide, left2 + Inches(0.25), col_top + Inches(2.1), col_w - Inches(0.5),
             Inches(0.4), 'New this release (2):', font_size=13, bold=True, color=DARK_GREEN)
add_text_box(slide, left2 + Inches(0.25), col_top + Inches(2.5), col_w - Inches(0.5),
             Inches(0.5), 'Kusaal · Gurene (Frafra)', font_size=15, bold=True, color=DARK)
add_text_box(slide, left2 + Inches(0.25), col_top + Inches(3.15), col_w - Inches(0.5),
             Inches(2.0),
             'Both are northern Ghanaian languages in the Mabia/Gur family. '
             'Currently use Dagbani as a fallback while native translations '
             'are being collected — speakers from these regions can already '
             'pick their language in the app today.',
             font_size=12, color=GRAY)


# ============================================================
# SLIDE 7: APP UPDATES IN ACTION (1/2) — screenshots
# Same layout as progress-report slide 6: 2.8" × 5.3" phone screenshots
# in a row, 13pt dark-green caption centered beneath each.
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, WHITE)
slide_header(slide, "App Updates in Action (1/2)",
             "Smart Pre-Check  |  Fingerprint Login  |  Languages")

shots_a = [
    ('1.png', 'Smart Pre-Check'),
    ('4.png', 'Fingerprint Login'),
    ('2.png', '9 Languages'),
]
# Card-with-phone tiles, mirroring progress-report slide 6's look.
phone_w = Inches(3.0)
phone_h = Inches(5.5)
card_w = Inches(3.7)
card_h = Inches(6.0)
# 3 cards with breathing room between them: 3*3.7 + 2*0.55 = 12.2"; margin = 0.57"
gap_a = Inches(0.55)
x_pos = Inches(0.57)
card_top = Inches(1.4)
for fname, label in shots_a:
    add_phone_tile(slide, os.path.join(FRAMED_DIR, fname), label,
                    x_pos, card_top, card_w, card_h, phone_w, phone_h)
    x_pos += card_w + gap_a


# ============================================================
# SLIDE 8: APP UPDATES IN ACTION (2/2) — screenshots
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, WHITE)
slide_header(slide, "App Updates in Action (2/2)",
             "Smoother Analytics  |  Direct Feedback Channel")

shots_b = [
    ('5.png', 'Smoother Analytics (Spline Chart)'),
    ('3.png', 'Talk to Us — Direct Feedback'),
]
# 2 cards, well-spaced: 2*3.7 + 1*1.2 = 8.6"; margin = (13.333-8.6)/2 = 2.37"
gap_b = Inches(1.2)
x_pos = Inches(2.37)
for fname, label in shots_b:
    add_phone_tile(slide, os.path.join(FRAMED_DIR, fname), label,
                    x_pos, card_top, card_w, card_h, phone_w, phone_h)
    x_pos += card_w + gap_b


# ============================================================
# SLIDE 9: STATUS — LIVE
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, WHITE)
slide_header(slide, "Release Status",
             "Where each component stands right now")

# Big "LIVE" banner
add_shape_bg(slide, Inches(0.7), Inches(1.6), Inches(12), Inches(1.0),
             RGBColor(40, 167, 69))
add_text_box(slide, Inches(0.7), Inches(1.78), Inches(12), Inches(0.6),
             '✅  Now Live on Google Play Store',
             font_size=26, bold=True, color=WHITE, alignment=PP_ALIGN.CENTER)

# Status table-like rows
rows = [
    ('Backend',        'Live in production',      'AWS EC2 · SSL valid through 4 Jul 2026',  GREEN),
    ('Mobile (Android)', 'Live on Play Store',    '1.2.0 (build 9) · 65.4 MB · signed',      GREEN),
    ('Play Store rollout', 'Auto-update in progress', 'Existing users receive update over 24–48h', ACCENT_BLUE),
    ('Install base',   '9 users · 177 countries', 'Per Play Console dashboard',              ACCENT_ORANGE),
]

row_top = Inches(2.95)
row_h = Inches(0.85)
row_gap = Inches(0.15)

for area, state, detail, color in rows:
    add_shape_bg(slide, Inches(0.7), row_top, Inches(0.18), row_h, color)
    add_shape_bg(slide, Inches(0.88), row_top, Inches(11.82), row_h, LIGHT_BG)
    add_text_box(slide, Inches(1.05), row_top + Inches(0.12), Inches(2.8),
                 Inches(0.4), area, font_size=14, bold=True, color=DARK)
    add_text_box(slide, Inches(3.9), row_top + Inches(0.12), Inches(3.5),
                 Inches(0.4), state, font_size=14, bold=True, color=color)
    add_text_box(slide, Inches(1.05), row_top + Inches(0.45), Inches(11.4),
                 Inches(0.4), detail, font_size=12, color=GRAY)
    row_top += row_h + row_gap


# ============================================================
# SLIDE 8: WHAT THIS MEANS FOR USERS
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, WHITE)
slide_header(slide, "What This Means for Users",
             "Translating shipped features into user value")

impact_items = [
    ('Smarter AI over time',
     'Every correction submitted by farmers and extension officers becomes training '
     'data for the next model. This release lays the foundation for a data flywheel — '
     'the model improves with use.'),
    ('Faster daily entry',
     'Fingerprint login removes a daily friction point. Users no longer retype '
     'their password each time they open the app.'),
    ('Higher trust in results',
     'The non-onion pre-check eliminates a class of confidently-wrong diagnoses '
     'that previously eroded user confidence.'),
    ('Wider linguistic reach',
     'Northern Ghanaian Kusaal and Gurene/Frafra speakers are now first-class users '
     'of the app — visible in the picker, with native translations on the way.'),
]

top = Inches(1.55)
h = Inches(1.3)
gap = Inches(0.13)
for title, body in impact_items:
    add_shape_bg(slide, Inches(0.7), top, Inches(12), h, LIGHT_GREEN_BG)
    add_shape_bg(slide, Inches(0.7), top, Inches(0.15), h, GREEN)
    add_text_box(slide, Inches(1.0), top + Inches(0.15), Inches(11.5),
                 Inches(0.4), title, font_size=16, bold=True, color=DARK_GREEN)
    add_text_box(slide, Inches(1.0), top + Inches(0.55), Inches(11.5),
                 Inches(0.7), body, font_size=12, color=DARK)
    top += h + gap


# ============================================================
# SLIDE 9: RISKS / WATCH ITEMS
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, WHITE)
slide_header(slide, "Risks & Watch Items",
             "What to keep an eye on going forward")

risk_items = [
    ('Small install base',
     '9 users today — corrections will trickle in until the user base grows. '
     'Pair this release with growth and outreach activity to maximise feedback volume.',
     ACCENT_ORANGE),
    ('Native translations pending',
     'Kusaal and Gurene currently fall back to Dagbani text. The fallback is '
     'functional but not native — translator engagement is the next step.',
     ACCENT_BLUE),
    ('Android 15 edge-to-edge deprecation',
     'A non-blocking warning from Play Console. Has to be addressed before '
     'Aug 2026 when Google starts enforcing it for new uploads.',
     ACCENT_ORANGE),
]

top = Inches(1.55)
h = Inches(1.55)
gap = Inches(0.18)
for title, body, color in risk_items:
    add_shape_bg(slide, Inches(0.7), top, Inches(12), h, RGBColor(255, 247, 230))
    add_shape_bg(slide, Inches(0.7), top, Inches(0.15), h, color)
    add_text_box(slide, Inches(1.0), top + Inches(0.18), Inches(11.5),
                 Inches(0.5), title, font_size=18, bold=True, color=color)
    add_text_box(slide, Inches(1.0), top + Inches(0.7), Inches(11.5),
                 Inches(0.85), body, font_size=13, color=DARK)
    top += h + gap


# ============================================================
# SLIDE 10: CLOSING
# ============================================================
slide = prs.slides.add_slide(prs.slide_layouts[6])
add_bg(slide, DARK_GREEN)
add_shape_bg(slide, Inches(0), Inches(0), prs.slide_width, prs.slide_height,
             RGBColor(38, 120, 45))

if os.path.exists(ONION_IMG):
    slide.shapes.add_picture(ONION_IMG, Inches(5.65), Inches(0.8), Inches(2.0), Inches(2.0))

add_text_box(slide, Inches(1), Inches(3.1), Inches(11.3), Inches(0.9),
             'OnionGuard 1.2.0 is Live',
             font_size=44, bold=True, color=WHITE, alignment=PP_ALIGN.CENTER)

add_text_box(slide, Inches(1), Inches(4.1), Inches(11.3), Inches(0.6),
             'Thank you to the team and to every farmer using the app.',
             font_size=20, color=SUBTITLE_GREEN, alignment=PP_ALIGN.CENTER)

add_shape_bg(slide, Inches(5.65), Inches(5.0), Inches(2.0), Pt(3), WHITE)

add_text_box(slide, Inches(1), Inches(5.3), Inches(11.3), Inches(0.5),
             'Apr 28 – Apr 29, 2026',
             font_size=16, color=WHITE, alignment=PP_ALIGN.CENTER)
add_text_box(slide, Inches(1), Inches(5.8), Inches(11.3), Inches(0.5),
             'Nkabom Honours Team  ·  University of Ghana',
             font_size=14, color=SOFT_GREEN, alignment=PP_ALIGN.CENTER)


# ============================================================
# SAVE
# ============================================================
output = "C:/Users/12345/Desktop/Projects/OnionGuard/OnionGuard-UpdateReport-v1.2.0.pptx"
prs.save(output)
print(f"Saved: {output}")
print(f"Slides: {len(prs.slides)}")
