# Instagram Content Publishing Automation

This small Python utility automates creating media containers and publishing content to Instagram Professional accounts using the Instagram Graph API.

Features
- Create single-image or single-video containers (using public `image_url` / `video_url`)
- Create carousel containers from up to 10 child containers
- Publish containers to produce a final media post
- Check container `status_code` and content publishing rate limits

Requirements
- Python 3.8+
- A valid Instagram user ID (`IG_USER_ID`) and Instagram access token (`ACCESS_TOKEN`) with the proper permissions:
  - `instagram_content_publish` and `instagram_basic` or `instagram_business_content_publish` and `instagram_business_basic` depending on access level
- Media must be publicly accessible URLs (the script cURLs the URL when creating containers). For local files, upload them to a public host or implement resumable upload for large video files.

Quickstart

1. Install dependencies:
```powershell
python -m pip install -r requirements.txt
```

2. Copy `.env.example` to `.env` and fill `ACCESS_TOKEN` and `IG_USER_ID`.

3. Create a single-image post:
```powershell
python post_instagram.py post --image-url "https://example.com/photo.jpg" --caption "Hello from API" --alt-text "A sunny beach"
```

4. Create a carousel post (example outline): first create individual children with `--image-url`, note their returned container IDs, then run:
```powershell
python post_instagram.py carousel --children "<ID1>,<ID2>" --caption "Carousel caption"
```

Notes
- The script uses public URLs for media. For local files you must host them publicly (CDN, object storage, or other) or implement resumable uploads for videos using `rupload.facebook.com`.
- The Instagram Platform enforces rate limits (100 published posts per 24 hours for API-published posts). Use `status` and `rate-limit` commands to check.

See `python post_instagram.py --help` for full usage.