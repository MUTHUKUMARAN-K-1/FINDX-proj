Firebase Storage setup for local-file uploads

This project supports uploading local files to Firebase Storage (Google Cloud Storage) and then publishing to Instagram using the resulting public URL.

Steps

1. Create a Firebase project at https://console.firebase.google.com and enable Storage.
2. In the Google Cloud Console, create a service account with the role "Storage Object Admin" and grant it access to the storage bucket.
3. Download the JSON key for that service account and store it securely on your machine.
4. Set the environment variable so the google-cloud-storage client can find credentials:

PowerShell:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service-account.json"
$env:FIREBASE_STORAGE_BUCKET = "your-project-id.appspot.com"
```

5. Install dependencies:

```powershell
python -m pip install -r requirements.txt
```

6. Use the CLI:

- Upload a local file and get a public URL:

```powershell
python .\post_instagram.py upload-local "C:\path\to\photo.jpg"
```

- Upload and publish:

```powershell
python .\post_instagram.py post-local "C:\path\to\photo.jpg" --caption "Caption text"
```

Notes

- The script will attempt to make the uploaded object public using `blob.make_public()`. If your bucket configuration prevents that, the script will fall back to generating a signed URL valid for 7 days.
- Ensure the service account has adequate permissions to upload and to make objects public (if you intend public objects). If you want permanent public objects, you can change the bucket's IAM/ACL policies accordingly.
- For production microservices, prefer using more controlled access (signed URLs or restricted buckets) rather than making objects public permanently.
