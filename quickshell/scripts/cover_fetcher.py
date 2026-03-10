#!/usr/bin/env python3
import sys
import json
import urllib.request
import urllib.parse
import os
import hashlib

# ================= 配置区 =================
CACHE_DIR = os.path.expanduser("~/.cache/qs_covers")
if not os.path.exists(CACHE_DIR):
    os.makedirs(CACHE_DIR)

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
}
# =========================================

def get_cache_path(title, artist):
    safe_name = f"{title}-{artist}".encode("utf-8", errors="ignore")
    hash_str = hashlib.md5(safe_name).hexdigest()
    # 存储下载后的 JPG 文件路径
    return os.path.join(CACHE_DIR, f"{hash_str}.jpg")

def fetch_itunes_cover(title, artist):
    """从 iTunes 搜索封面"""
    keyword = f"{title} {artist}"
    url = f"https://itunes.apple.com/search?term={urllib.parse.quote(keyword)}&media=music&limit=1"
    
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            if data.get("resultCount", 0) > 0:
                # 替换为 600x600 获取高清封面
                return data["results"][0]["artworkUrl100"].replace("100x100", "600x600")
    except Exception:
        pass
    return None

def download_image(url, save_path):
    """下载图片到本地"""
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=10) as response:
            with open(save_path, 'wb') as f:
                f.write(response.read())
            return True
    except Exception:
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(0)

    title = sys.argv[1]
    artist = sys.argv[2] if len(sys.argv) > 2 else ""

    # 1. 构造缓存路径
    img_path = get_cache_path(title, artist)

    # 2. 如果缓存存在，直接输出路径并退出
    if os.path.exists(img_path):
        sys.stdout.write(img_path)
        sys.exit(0)

    # 3. 搜索 URL
    cover_url = fetch_itunes_cover(title, artist)
    
    if cover_url:
        # 4. 下载并保存
        if download_image(cover_url, img_path):
            sys.stdout.write(img_path)
        else:
            # 下载失败则输出空
            sys.stdout.write("")
    else:
        sys.stdout.write("")
