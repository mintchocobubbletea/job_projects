from PIL import Image, ImageDraw

def make_rounded_icon(input_path, output_path, size):
    img = Image.open(input_path).convert("RGBA")
    
    # 흰색 여백 최대한 제거
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    
    # 여백 5%만 추가
    w, h = img.size
    pad = int(min(w, h) * 0.05)
    new_size = max(w, h) + pad * 2
    padded = Image.new("RGBA", (new_size, new_size), (255, 255, 255, 0))
    padded.paste(img, ((new_size - w) // 2, (new_size - h) // 2))
    img = padded
    
    img = img.resize((size, size), Image.LANCZOS)
    
    # 둥근 마스크 생성
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    radius = int(size * 0.22)
    draw.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=255)
    
    # 흰색 배경
    result = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    result.paste(img, mask=img.split()[3])
    
    # 둥근 마스크 적용
    final = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    final.paste(result, mask=mask)
    final.save(output_path, "PNG")
    print(f"생성 완료: {output_path} ({size}x{size})")

sizes = {
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": 48,
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": 72,
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": 96,
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": 144,
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": 192,
    "android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png": 48,
    "android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png": 72,
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png": 96,
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png": 144,
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png": 192,
}

for path, size in sizes.items():
    make_rounded_icon("app_icon.png", path, size)

print("모든 아이콘 생성 완료!")
