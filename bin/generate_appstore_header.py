#!/usr/bin/env python3
"""Generate App Store Connect product page header with TouchTutor musical note."""
from PIL import Image, ImageDraw, ImageFont
import os

# App Store Connect product page header specs: 3840x1646, 21:9, PNG, no transparency
width = 3840
height = 1646

# Brand colors
dark_blue = (13, 71, 101)
medium_blue = (30, 100, 145)
white = (255, 255, 255)

# Create image with gradient background
img = Image.new('RGB', (width, height))
pixels = img.load()

# Create a subtle gradient from dark blue (top-left) to medium blue (bottom-right)
for y in range(height):
    for x in range(width):
        fx = x / width
        fy = y / height
        r = int(dark_blue[0] * (1 - fx * 0.5 - fy * 0.3) + medium_blue[0] * (fx * 0.5 + fy * 0.3))
        g = int(dark_blue[1] * (1 - fx * 0.5 - fy * 0.3) + medium_blue[1] * (fx * 0.5 + fy * 0.3))
        b = int(dark_blue[2] * (1 - fx * 0.5 - fy * 0.3) + medium_blue[2] * (fx * 0.5 + fy * 0.3))
        pixels[x, y] = (r, g, b)

draw = ImageDraw.Draw(img)

# Draw subtle music staff lines in the background
staff_y_start = int(height * 0.3)
staff_spacing = int(height * 0.06)

for i in range(5):
    y = staff_y_start + i * staff_spacing
    for x in range(width):
        current = pixels[x, y]
        r = int(current[0] * 0.85 + 255 * 0.15)
        g = int(current[1] * 0.85 + 255 * 0.15)
        b = int(current[2] * 0.85 + 255 * 0.15)
        pixels[x, y] = (r, g, b)

# Load fonts
note_font_path = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"
title_font_path = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"

# Unicode musical notes
NOTE_DOUBLE = '♫'  # Double beamed eighth notes (main logo)
NOTE_SINGLE = '♪'  # Single eighth note (decorative)
NOTE_QUARTER = '♩'  # Quarter note (decorative)

# Draw scattered decorative notes in the background
decorative_notes = [
    (350, 250, NOTE_SINGLE, 120, 0.2),
    (3300, 200, NOTE_DOUBLE, 150, 0.15),
    (500, 1250, NOTE_QUARTER, 100, 0.2),
    (3100, 1150, NOTE_SINGLE, 130, 0.15),
    (1400, 150, NOTE_SINGLE, 90, 0.1),
    (2500, 1350, NOTE_DOUBLE, 110, 0.1),
    (150, 700, NOTE_QUARTER, 80, 0.15),
    (3600, 800, NOTE_SINGLE, 85, 0.12),
    (900, 400, NOTE_SINGLE, 70, 0.08),
    (2900, 500, NOTE_QUARTER, 75, 0.08),
    (1100, 1100, NOTE_DOUBLE, 65, 0.07),
    (2700, 350, NOTE_SINGLE, 60, 0.07),
]

for x, y, note_char, size, opacity in decorative_notes:
    font = ImageFont.truetype(note_font_path, size)
    # Blend color with background opacity
    r = int(dark_blue[0] * (1 - opacity) + white[0] * opacity)
    g = int(dark_blue[1] * (1 - opacity) + white[1] * opacity)
    b = int(dark_blue[2] * (1 - opacity) + white[2] * opacity)
    note_color = (r, g, b)
    bbox = draw.textbbox((0, 0), note_char, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((x - tw // 2, y - th // 2), note_char, fill=note_color, font=font)

# Draw the main large Unicode musical note in the center
main_note_size = int(700)
main_font = ImageFont.truetype(note_font_path, main_note_size)
main_bbox = draw.textbbox((0, 0), NOTE_DOUBLE, font=main_font)
main_w = main_bbox[2] - main_bbox[0]
main_h = main_bbox[3] - main_bbox[1]
main_x = (width - main_w) // 2
main_y = (height - main_h) // 2

draw.text((main_x, main_y), NOTE_DOUBLE, fill=white, font=main_font)

# Save the image
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
output_path = os.path.join(project_root, 'Resources', 'AppStoreHeader.png')
img.save(output_path, 'PNG')
print(f'Header saved to {output_path}')
print(f'Dimensions: {img.size}')
print(f'Mode: {img.mode}')


# --- Search Results Image (3:2, 1920x1280 min, 3840x2560 max) ---
s_width = 1920
s_height = 1280

s_img = Image.new('RGB', (s_width, s_height))
s_pixels = s_img.load()

# Same gradient background
for y in range(s_height):
    for x in range(s_width):
        fx = x / s_width
        fy = y / s_height
        r = int(dark_blue[0] * (1 - fx * 0.5 - fy * 0.3) + medium_blue[0] * (fx * 0.5 + fy * 0.3))
        g = int(dark_blue[1] * (1 - fx * 0.5 - fy * 0.3) + medium_blue[1] * (fx * 0.5 + fy * 0.3))
        b = int(dark_blue[2] * (1 - fx * 0.5 - fy * 0.3) + medium_blue[2] * (fx * 0.5 + fy * 0.3))
        s_pixels[x, y] = (r, g, b)

s_draw = ImageDraw.Draw(s_img)

# Draw scattered decorative notes
decorative_notes_small = [
    (150, 100, NOTE_SINGLE, 60, 0.2),
    (1700, 80, NOTE_DOUBLE, 75, 0.15),
    (200, 1100, NOTE_QUARTER, 50, 0.2),
    (1600, 1050, NOTE_SINGLE, 65, 0.15),
    (600, 60, NOTE_SINGLE, 45, 0.1),
    (1200, 1150, NOTE_DOUBLE, 55, 0.1),
    (60, 300, NOTE_QUARTER, 40, 0.15),
    (1800, 400, NOTE_SINGLE, 42, 0.12),
    (400, 200, NOTE_SINGLE, 35, 0.08),
    (1400, 250, NOTE_QUARTER, 37, 0.08),
    (500, 550, NOTE_DOUBLE, 32, 0.07),
    (1300, 170, NOTE_SINGLE, 30, 0.07),
]

for x, y, note_char, size, opacity in decorative_notes_small:
    font = ImageFont.truetype(note_font_path, size)
    r = int(dark_blue[0] * (1 - opacity) + white[0] * opacity)
    g = int(dark_blue[1] * (1 - opacity) + white[1] * opacity)
    b = int(dark_blue[2] * (1 - opacity) + white[2] * opacity)
    note_color = (r, g, b)
    bbox = s_draw.textbbox((0, 0), note_char, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    s_draw.text((x - tw // 2, y - th // 2), note_char, fill=note_color, font=font)

# Main large Unicode musical note, centered
main_note_size_s = 350
main_font_s = ImageFont.truetype(note_font_path, main_note_size_s)
main_bbox_s = s_draw.textbbox((0, 0), NOTE_DOUBLE, font=main_font_s)
main_w_s = main_bbox_s[2] - main_bbox_s[0]
main_h_s = main_bbox_s[3] - main_bbox_s[1]
main_x_s = (s_width - main_w_s) // 2
main_y_s = (s_height - main_h_s) // 2

s_draw.text((main_x_s, main_y_s), NOTE_DOUBLE, fill=white, font=main_font_s)

# Save search results image
s_output_path = os.path.join(project_root, 'Resources', 'AppStoreSearchResults.png')
s_img.save(s_output_path, 'PNG')
print(f'Search results saved to {s_output_path}')
print(f'Dimensions: {s_img.size}')
print(f'Mode: {s_img.mode}')
