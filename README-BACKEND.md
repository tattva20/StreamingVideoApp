# Streaming Video Backend Setup

This document explains how to set up the backend for the Streaming Video App.

## Current Architecture

The app uses:
- **RemoteVideoLoader**: Fetches videos from an HTTP API
- **LocalVideoLoader**: Caches videos in CoreData
- **VideoLoaderComposite**: Tries remote first, falls back to cache
- **VideoLoaderCacheDecorator**: Automatically saves successful remote loads to cache

## Option 1: Local Development Server (Fastest)

1. Start the local server:
```bash
cd /Users/octaviorojas/Development/StreamingVideoApp/StreamingCore
python3 serve-videos.py
```

2. The server will serve `videos.json` at `http://localhost:8000/videos.json`

3. Run the app - it's already configured to use localhost!

## Option 2: GitHub Pages (Production-Ready)

### Step 1: Create a GitHub Repository

1. Go to https://github.com/new
2. Repository name: `streaming-videos-api`
3. Make it **Public**
4. Click "Create repository"

### Step 2: Upload videos.json

```bash
cd /path/to/your/repo
cp /Users/octaviorojas/Development/StreamingVideoApp/StreamingCore/videos.json .
git add videos.json
git commit -m "Add videos API endpoint"
git push origin main
```

### Step 3: Enable GitHub Pages

1. Go to Settings → Pages
2. Source: "Deploy from a branch"
3. Branch: main / (root)
4. Save

### Step 4: Update SceneDelegate.swift

Replace the localhost URL with:
```swift
let apiURL = URL(string: "https://YOUR_GITHUB_USERNAME.github.io/streaming-videos-api/videos.json")!
```

Your JSON will be available at: `https://YOUR_GITHUB_USERNAME.github.io/streaming-videos-api/videos.json`

## Option 3: Vercel/Netlify (Alternative)

You can also host the JSON on Vercel or Netlify for free:

### Vercel:
```bash
cd /Users/octaviorojas/Development/StreamingVideoApp/StreamingCore
vercel --prod
```

### Netlify:
Drag and drop the `videos.json` file to https://app.netlify.com/drop

## JSON Format

The API expects this exact structure:

```json
{
  "videos": [
    {
      "id": "uuid-string",
      "title": "Video Title",
      "description": "Description (optional)",
      "url": "https://direct-video-url.mp4",
      "thumbnail_url": "https://thumbnail-image.jpg",
      "duration": 596.0
    }
  ]
}
```

**Important**: Use `thumbnail_url` (snake_case) - it's automatically converted to camelCase in Swift.

## Testing the Setup

### Test Remote Loading
1. Start your server/deploy to GitHub Pages
2. Run the app
3. Pull down to refresh
4. Videos should load from the remote API
5. Check they're cached by:
   - Stopping the server
   - Force quitting the app
   - Restarting the app
   - Videos should still appear (from cache)

### Test Cache Fallback
1. Start app with server running (loads from remote)
2. Stop the server
3. Force quit app
4. Restart app
5. Videos should load from cache

### Test Error Handling
1. Stop the server
2. Delete app data (Settings → App → Delete App)
3. Reinstall and run
4. Should show error message (no remote, no cache)

## Current Video Sources

All videos use Google Cloud Storage (free, publicly available):

1. **Big Buck Bunny** (596s) - https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
2. **Elephant Dream** (653s) - https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4
3. **For Bigger Blazes** (15s) - https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4
4. **Sintel** (888s) - https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4
5. **Tears of Steel** (734s) - https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4

All videos are from the Blender Foundation (open movies, public domain).

## Adding More Videos

To add more videos to the JSON:

1. Find direct MP4 URLs (must be HTTPS for iOS)
2. Add to `videos.json` with the required format
3. Commit and push
4. Videos will appear in the app after next refresh

## Troubleshooting

### App Transport Security (ATS)
If using HTTP (localhost), ATS is already configured in Info.plist.
For production, always use HTTPS.

### Cache Issues
Clear cache by deleting the app and reinstalling.

### Server Not Reachable
- Check server is running: `curl http://localhost:8000/videos.json`
- Check iOS simulator can reach localhost (it should work by default)
- For physical device, use your Mac's IP address instead of localhost
