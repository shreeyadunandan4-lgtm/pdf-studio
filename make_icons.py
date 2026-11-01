import glob, os
from PIL import Image, ImageDraw

res = 'android/app/src/main/res'
logo = Image.open('logo.png').convert('RGB')
w, h = logo.size
s = min(w, h)
logo = logo.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))

# purane icons hatao
for f in glob.glob(res + '/mipmap-*/ic_launcher*'):
    os.remove(f)

legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
fore = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}

for d, px in legacy.items():
    os.makedirs(f'{res}/mipmap-{d}', exist_ok=True)
    big = logo.resize((px * 4, px * 4), Image.LANCZOS).convert('RGBA')
    mask = Image.new('L', big.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, big.size[0] - 1, big.size[1] - 1),
                                           radius=int(big.size[0] * 0.22), fill=255)
    big.putalpha(mask)
    big.resize((px, px), Image.LANCZOS).save(f'{res}/mipmap-{d}/ic_launcher.png')

for d, px in fore.items():
    os.makedirs(f'{res}/mipmap-{d}', exist_ok=True)
    canvas = Image.new('RGBA', (px, px), (0, 0, 0, 0))
    inner = int(px * 0.66)
    small = logo.resize((inner, inner), Image.LANCZOS).convert('RGBA')
    mask = Image.new('L', (inner, inner), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, inner - 1, inner - 1),
                                           radius=int(inner * 0.22), fill=255)
    small.putalpha(mask)
    canvas.paste(small, ((px - inner) // 2, (px - inner) // 2), small)
    canvas.save(f'{res}/mipmap-{d}/ic_launcher_foreground.png')

os.makedirs(res + '/mipmap-anydpi-v26', exist_ok=True)
open(res + '/mipmap-anydpi-v26/ic_launcher.xml', 'w').write(
'''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''')
os.makedirs(res + '/values', exist_ok=True)
open(res + '/values/ic_launcher_background.xml', 'w').write(
'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#02040F</color>
</resources>
''')
print('icons ready')
