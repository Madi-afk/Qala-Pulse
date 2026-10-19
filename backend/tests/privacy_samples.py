"""Project-authored synthetic street/plate scenes; no real registration numbers."""

from PIL import Image, ImageDraw, ImageFont


def street_scene(*, plate: bool = True) -> Image.Image:
    image = Image.new("RGB", (960, 640), (116, 125, 130))
    draw = ImageDraw.Draw(image)
    for y in range(0, 640, 8):
        draw.line((0, y, 960, y), fill=(94 + y % 25, 100 + y % 25, 108 + y % 25))
    draw.polygon([(40, 440), (180, 400), (270, 460), (225, 580), (70, 570)], fill=(40, 42, 44))
    draw.line([(40, 440), (180, 400), (270, 460), (225, 580)], fill=(203, 196, 179), width=4)
    for x in range(310, 520, 55):
        draw.rectangle((x, 480, x + 25, 590), fill=(226, 225, 215))
    draw.rounded_rectangle((555, 150, 910, 380), radius=35, fill=(41, 65, 83))
    draw.rectangle((610, 175, 855, 240), fill=(110, 146, 156))
    if plate:
        draw.rounded_rectangle((615, 286, 867, 351), radius=4, fill=(247, 246, 233))
        draw.text((630, 302), "123 ABC 02", font=ImageFont.load_default(size=32), fill=(15, 15, 15))
    return image
