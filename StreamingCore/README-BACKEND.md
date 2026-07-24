# Streaming Video Backend Setup

This document explains how to set up the backend for the Streaming Video App.

## Current Architecture

The app uses:
- **RemoteVideoLoader**: Fetches videos from an HTTP API
- **LocalVideoLoader**: Caches videos in CoreData
- **VideoService**: Coordinates remote-with-local-fallback loading (`loadRemoteVideosWithLocalFallback()`) and saves successful remote loads to the cache

### Production Backend

The shipped app targets a hosted API on Vercel. The base URL is defined in
`StreamingCorePlayback/VideoService.swift` (a single `VideoService` instance serves
both the iOS and tvOS app targets — it is not set in `SceneDelegate.swift`):

- **Base URL**: `https://streaming-videos-api.vercel.app`
- **Videos** (paginated): `/v1/videos?limit=10&after_id=<uuid>`
- **Comments**: `/v1/videos/{id}/comments`
- Video and image URLs are returned inline in the API response.

The static `videos.json` format described below is used only by the local
`serve-videos.py` development server. To point the app at a local server or a
different host, change `baseURL` in `VideoService.swift`.

## Option 1: Local Development Server (Fastest)

1. Start the local server:
```bash
cd /Users/octaviorojas/Development/active/Tattva/StreamingCore
python3 serve-videos.py
```

2. The server will serve `videos.json` at `http://localhost:8000/videos.json`

3. Point the app at the local server by changing `baseURL` in
   `StreamingCorePlayback/VideoService.swift` (it defaults to the Vercel URL), then run
   the app. Note: `serve-videos.py` serves a single flat `videos.json`, whereas the app
   requests the paginated `/v1/videos` endpoint, so match the path when using local dev.

## Option 2: GitHub Pages (Production-Ready)

### Step 1: Create a GitHub Repository

1. Go to https://github.com/new
2. Repository name: `streaming-videos-api`
3. Make it **Public**
4. Click "Create repository"

### Step 2: Upload videos.json

```bash
cd /path/to/your/repo
cp /Users/octaviorojas/Development/active/Tattva/StreamingCore/videos.json .
git add videos.json
git commit -m "Add videos API endpoint"
git push origin main
```

### Step 3: Enable GitHub Pages

1. Go to Settings → Pages
2. Source: "Deploy from a branch"
3. Branch: main / (root)
4. Save

### Step 4: Update the base URL

The base URL is defined in `StreamingCorePlayback/VideoService.swift`, not in
`SceneDelegate.swift`. Change it to your host:
```swift
private lazy var baseURL = URL(string: "https://YOUR_GITHUB_USERNAME.github.io/streaming-videos-api")!
```

Note: static GitHub Pages hosting serves a flat JSON file, while the app requests the
paginated `/v1/videos` endpoint. The shipped app instead uses the Vercel API at
`https://streaming-videos-api.vercel.app` (see Current Architecture above).

## Option 3: Vercel/Netlify (Alternative)

You can also host the JSON on Vercel or Netlify for free:

### Vercel:
```bash
cd /Users/octaviorojas/Development/active/Tattva/StreamingCore
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
`Info.plist` does not define an `NSAppTransportSecurity` key, so default ATS applies and
the shipped app uses the HTTPS Vercel endpoint. To reach an HTTP `localhost` server for
local dev, add an ATS exception in `Info.plist`. For production, always use HTTPS.

### Cache Issues
Clear cache by deleting the app and reinstalling.

### Server Not Reachable
- Check server is running: `curl http://localhost:8000/videos.json`
- Check iOS simulator can reach localhost (it should work by default)
- For physical device, use your Mac's IP address instead of localhost
