#!/usr/bin/env python3
"""Simple Instagram Graph API publisher CLI.

Supports creating media containers (image/video), carousel containers, publishing, and status checks.

Important: media must be reachable via public URLs when creating containers.
"""
import os
import sys
import time
import argparse
import logging
from typing import Optional

import requests
import re
import datetime
try:
    from google.cloud import storage
except Exception:
    storage = None
from dotenv import load_dotenv

load_dotenv()

LOG = logging.getLogger("ig_publisher")
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

ACCESS_TOKEN = os.getenv("ACCESS_TOKEN")
IG_USER_ID = os.getenv("IG_USER_ID")
API_VERSION = os.getenv("API_VERSION", "v17.0")
GRAPH_HOST = os.getenv("GRAPH_HOST", "graph.instagram.com")


def api_url(path: str, host: Optional[str] = None) -> str:
    host = host or GRAPH_HOST
    return f"https://{host}/{API_VERSION}/{path}"


def upload_file_to_firebase(local_path: str, bucket_name: str, dest_name: Optional[str] = None,
                            make_public: bool = True) -> str:
    """Upload a local file to Firebase Storage (Google Cloud Storage) and return a public URL.

    Requires the environment variable `GOOGLE_APPLICATION_CREDENTIALS` to point to a service
    account JSON with access to the storage bucket, and `FIREBASE_STORAGE_BUCKET` to be set.
    """
    if storage is None:
        raise RuntimeError("google-cloud-storage package is not installed. Install from requirements.txt")
    if not os.path.isfile(local_path):
        raise FileNotFoundError(f"Local file not found: {local_path}")
    if not bucket_name:
        raise ValueError("FIREBASE_STORAGE_BUCKET is not set")
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    dest_name = dest_name or os.path.basename(local_path)
    blob = bucket.blob(dest_name)
    blob.upload_from_filename(local_path)
    if make_public:
        try:
            blob.make_public()
            return blob.public_url
        except Exception:
            # If make_public fails, try generating a signed URL
            pass
    # Fallback to signed URL for 7 days
    url = blob.generate_signed_url(expiration=datetime.timedelta(days=7))
    return url


def convert_google_drive_url(url: str) -> str:
    """Convert common Google Drive share URLs to a direct download URL when possible.

    Returns the original URL if no conversion was performed.
    """
    if not url:
        return url
    # patterns for Google Drive
    m = re.search(r"/file/d/([a-zA-Z0-9_-]+)", url)
    if m:
        fid = m.group(1)
        return f"https://drive.google.com/uc?export=download&id={fid}"
    m = re.search(r"[?&]id=([a-zA-Z0-9_-]+)", url)
    if "drive.google.com" in url and m:
        fid = m.group(1)
        return f"https://drive.google.com/uc?export=download&id={fid}"
    return url


def is_public_media_url(url: str, expect_image: bool = True) -> (bool, str):
    """Check that a URL is publicly reachable and that the Content-Type is acceptable.

    Returns (ok, content_type_or_error).
    """
    if not url:
        return False, "empty url"
    try:
        # Try HEAD first
        h = requests.head(url, allow_redirects=True, timeout=10)
        if h.status_code >= 400:
            # Try GET (some servers don't respond to HEAD)
            g = requests.get(url, stream=True, timeout=10)
            status = g.status_code
            ctype = g.headers.get("Content-Type", "")
        else:
            status = h.status_code
            ctype = h.headers.get("Content-Type", "")
    except requests.RequestException as e:
        return False, f"request failed: {e}"

    ctype = (ctype or "").lower()
    if status >= 400:
        return False, f"http status {status}"
    if expect_image:
        # Instagram only supports JPEG images for image posts
        if not ctype.startswith("image/"):
            return False, f"content-type not image/* ({ctype})"
        if not ctype.startswith("image/jpeg") and not ctype.startswith("image/jpg"):
            return False, f"image must be JPEG (content-type {ctype})"
    else:
        if not ctype.startswith("video/"):
            return False, f"content-type not video/* ({ctype})"
    return True, ctype


def create_media_container(ig_id: str, access_token: str, image_url: Optional[str] = None,
                           video_url: Optional[str] = None, media_type: Optional[str] = None,
                           is_carousel_item: bool = False, alt_text: Optional[str] = None,
                           caption: Optional[str] = None, children: Optional[str] = None) -> dict:
    """Create a media container for an image/video or a carousel.

    For images/videos the media must be a publicly accessible URL. For resumable uploads
    and large videos, a separate rupload flow is required (not implemented here).
    """
    if not access_token:
        raise ValueError("access_token is required")
    url = api_url(f"{ig_id}/media")
    payload = {"access_token": access_token}
    if caption:
        payload["caption"] = caption
    if children:
        payload["media_type"] = "CAROUSEL"
        payload["children"] = children
    else:
        if image_url:
            payload["image_url"] = image_url
            if media_type:
                payload["media_type"] = media_type
        if video_url:
            payload["video_url"] = video_url
            payload["media_type"] = media_type or "VIDEO"
    if is_carousel_item:
        payload["is_carousel_item"] = "true"
    if alt_text:
        # alt_text is supported for image posts (introduced Mar 24, 2025)
        payload["alt_text"] = alt_text

    LOG.debug("Creating container with payload: %s", payload)
    resp = requests.post(url, data=payload)
    try:
        resp.raise_for_status()
    except requests.HTTPError:
        LOG.error("Create container failed: %s", resp.text)
        raise
    return resp.json()


def publish_container(ig_id: str, access_token: str, creation_id: str) -> dict:
    if not access_token:
        raise ValueError("access_token is required")
    url = api_url(f"{ig_id}/media_publish")
    payload = {"access_token": access_token, "creation_id": creation_id}
    resp = requests.post(url, data=payload)
    try:
        resp.raise_for_status()
    except requests.HTTPError:
        LOG.error("Publish failed: %s", resp.text)
        raise
    return resp.json()


def get_container_status(container_id: str, access_token: str) -> dict:
    url = api_url(f"{container_id}")
    params = {"fields": "status_code", "access_token": access_token}
    resp = requests.get(url, params=params)
    try:
        resp.raise_for_status()
    except requests.HTTPError:
        LOG.error("Status check failed: %s", resp.text)
        raise
    return resp.json()


def get_rate_limit(ig_id: str, access_token: str) -> dict:
    url = api_url(f"{ig_id}/content_publishing_limit")
    params = {"access_token": access_token}
    resp = requests.get(url, params=params)
    try:
        resp.raise_for_status()
    except requests.HTTPError:
        LOG.error("Rate limit check failed: %s", resp.text)
        raise
    return resp.json()


def main():
    parser = argparse.ArgumentParser(description="Instagram content publisher CLI")
    sub = parser.add_subparsers(dest="cmd")

    p_post = sub.add_parser("post", help="Create and publish a single image or video post (public URL required)")
    p_post.add_argument("--image-url", help="Public URL to an image (JPEG only)")
    p_post.add_argument("--video-url", help="Public URL to a video")
    p_post.add_argument("--caption", help="Caption text")
    p_post.add_argument("--alt-text", help="Alt text for image posts")
    p_post.add_argument("--no-publish", action="store_true", help="Only create container, don't publish")

    p_car = sub.add_parser("carousel", help="Create and publish a carousel from child container IDs")
    p_car.add_argument("--children", required=True, help="Comma-separated list of child container IDs (max 10)")
    p_car.add_argument("--caption", help="Caption text")
    p_car.add_argument("--no-publish", action="store_true", help="Only create container, don't publish")

    p_status = sub.add_parser("status", help="Check container status")
    p_status.add_argument("container_id", help="Container ID to check")

    p_rate = sub.add_parser("rate-limit", help="Check content publishing rate limits for the account")

    p_val = sub.add_parser("validate-token", help="Validate the access token and show associated Instagram id/username")
    p_upload_local = sub.add_parser("upload-local", help="Upload local file to Firebase Storage and print public URL")
    p_upload_local.add_argument("file", help="Local file path to upload")
    p_upload_local.add_argument("--dest", help="Destination object name in bucket")
    p_upload_local.add_argument("--no-public", action="store_true", help="Do not make the uploaded file public (generate signed URL instead)")

    p_post_local = sub.add_parser("post-local", help="Upload local file to Firebase Storage then create and publish a post")
    p_post_local.add_argument("file", help="Local file path to upload and post")
    p_post_local.add_argument("--caption", help="Caption text")
    p_post_local.add_argument("--alt-text", help="Alt text for image posts")
    p_post_local.add_argument("--no-publish", action="store_true", help="Only create container, don't publish")

    args = parser.parse_args()

    access_token = ACCESS_TOKEN or os.getenv("ACCESS_TOKEN")
    ig_id = IG_USER_ID or os.getenv("IG_USER_ID")

    # Detect missing or placeholder values and give actionable instructions
    placeholders = {
        "YOUR_IG_USER_ID_HERE",
        "YOUR_IG_USER_ID",
        "YOUR_IG_ACCESS_TOKEN_HERE",
        "YOUR_ACCESS_TOKEN_HERE",
    }
    def looks_placeholder(value: Optional[str]) -> bool:
        if value is None:
            return True
        v = str(value).strip()
        if v == "":
            return True
        for p in placeholders:
            if p in v:
                return True
        return False

    if looks_placeholder(access_token):
        LOG.error("ACCESS_TOKEN is not set or still a placeholder.")
        LOG.error("Set a valid Instagram Graph API access token in environment or .env.")
        LOG.error("PowerShell (temporary for session):")
        LOG.error("  $env:ACCESS_TOKEN = \"<YOUR_ACCESS_TOKEN>\"")
        LOG.error("PowerShell (create/edit .env):")
        LOG.error("  Copy-Item .env.example .env -Force; notepad .env")
        sys.exit(1)

    if looks_placeholder(ig_id):
        LOG.warning("IG_USER_ID appears to be missing or a placeholder. You can fetch the numeric id with the `validate-token` command.")
    else:
        # If IG user id does not look numeric, warn but allow operations (we can still try)
        if not str(ig_id).strip().isdigit():
            LOG.warning("IG_USER_ID does not look like a numeric Instagram user id. The API expects a numeric id (e.g. 1784140...).")
            LOG.warning("Use `python post_instagram.py validate-token` to retrieve the numeric id for your token.")

    if args.cmd == "post":
        if not args.image_url and not args.video_url:
            LOG.error("Provide --image-url or --video-url for single posts")
            sys.exit(1)
        media_type = None
        if args.video_url:
            media_type = "VIDEO"
        elif args.image_url:
            media_type = "IMAGE"

        # Try to convert common Google Drive links to direct URLs
        image_url = args.image_url
        video_url = args.video_url
        if image_url and "drive.google.com" in image_url:
            image_url = convert_google_drive_url(image_url)
            LOG.info("Converted Google Drive URL to direct download URL: %s", image_url)
        if video_url and "drive.google.com" in video_url:
            video_url = convert_google_drive_url(video_url)
            LOG.info("Converted Google Drive URL to direct download URL: %s", video_url)

        # Validate URLs before calling the API to provide clearer errors
        if image_url:
            ok, info = is_public_media_url(image_url, expect_image=True)
            if not ok:
                LOG.error("Image URL validation failed: %s", info)
                LOG.error("Ensure the URL is publicly accessible and points to a JPEG image. See README for examples.")
                sys.exit(1)
        if video_url:
            ok, info = is_public_media_url(video_url, expect_image=False)
            if not ok:
                LOG.error("Video URL validation failed: %s", info)
                LOG.error("Ensure the URL is publicly accessible and points to a video file.")
                sys.exit(1)

        LOG.info("Creating media container...")
        resp = create_media_container(ig_id, access_token, image_url=image_url,
                                      video_url=video_url, media_type=media_type,
                                      alt_text=args.alt_text, caption=args.caption)
        print(resp)
        cid = resp.get("id")
        if not cid:
            LOG.error("Container creation did not return an id")
            sys.exit(1)
        if args.no_publish:
            LOG.info("Container created: %s (not publishing)", cid)
            return
        LOG.info("Publishing container %s...", cid)
        pub = publish_container(ig_id, access_token, cid)
        print(pub)

    elif args.cmd == "upload-local":
        bucket = os.getenv("FIREBASE_STORAGE_BUCKET")
        if not bucket:
            LOG.error("FIREBASE_STORAGE_BUCKET is not set in environment. Set it to your Firebase Storage bucket name.")
            sys.exit(1)
        try:
            public_url = upload_file_to_firebase(args.file, bucket, dest_name=args.dest, make_public=not args.no_public)
            print({"url": public_url})
        except Exception as e:
            LOG.error("Upload failed: %s", e)
            sys.exit(1)

    elif args.cmd == "post-local":
        bucket = os.getenv("FIREBASE_STORAGE_BUCKET")
        if not bucket:
            LOG.error("FIREBASE_STORAGE_BUCKET is not set in environment. Set it to your Firebase Storage bucket name.")
            sys.exit(1)
        try:
            public_url = upload_file_to_firebase(args.file, bucket, make_public=True)
            LOG.info("Uploaded file available at: %s", public_url)
        except Exception as e:
            LOG.error("Upload failed: %s", e)
            sys.exit(1)

        # Now create media container and publish using the uploaded URL
        media_type = "IMAGE"
        ok, info = is_public_media_url(public_url, expect_image=True)
        if not ok:
            LOG.error("Uploaded file URL validation failed: %s", info)
            sys.exit(1)
        LOG.info("Creating media container from uploaded file...")
        resp = create_media_container(ig_id, access_token, image_url=public_url, media_type=media_type, alt_text=args.alt_text, caption=args.caption)
        print(resp)
        cid = resp.get("id")
        if not cid:
            LOG.error("Container creation did not return an id")
            sys.exit(1)
        if args.no_publish:
            LOG.info("Container created: %s (not publishing)", cid)
            return
        LOG.info("Publishing container %s...", cid)
        pub = publish_container(ig_id, access_token, cid)
        print(pub)

    elif args.cmd == "carousel":
        children = args.children
        LOG.info("Creating carousel container with children: %s", children)
        resp = create_media_container(ig_id, access_token, children=children, caption=args.caption)
        print(resp)
        cid = resp.get("id")
        if not cid:
            LOG.error("Carousel container creation did not return an id")
            sys.exit(1)
        if args.no_publish:
            LOG.info("Carousel container created: %s (not publishing)", cid)
            return
        LOG.info("Publishing carousel %s...", cid)
        pub = publish_container(ig_id, access_token, cid)
        print(pub)

    elif args.cmd == "status":
        cid = args.container_id
        LOG.info("Checking status for container %s", cid)
        status = get_container_status(cid, access_token)
        print(status)

    elif args.cmd == "rate-limit":
        LOG.info("Checking rate limits for account %s", ig_id)
        rl = get_rate_limit(ig_id, access_token)
        print(rl)

    elif args.cmd == "validate-token":
        # Validate access token by calling /me and showing returned id/username
        LOG.info("Validating access token via /me...")
        try:
            url = api_url("me")
            params = {"fields": "id,username", "access_token": access_token}
            r = requests.get(url, params=params)
            r.raise_for_status()
            print(r.json())
        except requests.HTTPError:
            LOG.error("Token validation failed: %s", r.text)
            sys.exit(1)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
