# Testing Background Removal with WithoutBG

This guide shows you how to test the WithoutBG background removal API locally.

## Step 1: Set Up the Backend Server

### Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### Start the Server

```bash
python main.py
```

The server will start on `http://localhost:8000`

You should see:
```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

## Step 2: Test the Backend (Optional)

### Option A: Using the test script

```bash
# In the backend directory
python test_api.py path/to/your/test/image.jpg
```

### Option B: Using curl

```bash
curl -X POST "http://localhost:8000/remove-background" \
  -F "file=@test_image.jpg" \
  --output result.png
```

### Option C: Visit in browser

Open http://localhost:8000 in your browser to see the API info.

## Step 3: Configure iOS App

### For iOS Simulator

The simulator can connect to localhost directly:

1. Open `ClothesAI/Services/BackgroundRemovalService.swift`
2. Change these lines:

```swift
var method: BackgroundRemovalMethod = .api  // Change from .vision to .api
var apiBaseURL: String = "http://localhost:8000"
```

3. Build and run in simulator
4. Test with a photo!

### For Physical iPhone

Your iPhone can't access "localhost" - you need your Mac's IP address:

1. **Find your Mac's IP address:**
   ```bash
   ipconfig getifaddr en0
   # Or on older macOS:
   ifconfig en0 | grep inet
   ```

   Example output: `192.168.1.100`

2. **Update Info.plist to allow HTTP:**

   Add this to `ClothesAI/Info.plist` (already included):
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <true/>
   </dict>
   ```

3. **Update BackgroundRemovalService.swift:**
   ```swift
   var method: BackgroundRemovalMethod = .api
   var apiBaseURL: String = "http://192.168.1.100:8000"  // Use your Mac's IP
   ```

4. **Make sure:**
   - Your iPhone and Mac are on the same WiFi network
   - Your firewall allows connections on port 8000

5. Build and run on your iPhone!

## Step 4: Test in the App

1. Open the app
2. Tap "+" to add a new item
3. Take or choose a photo of clothing
4. Watch the console logs in Xcode to see the API communication
5. The background should be removed and replaced with white!

## Comparing Methods

### Vision Framework (Current Default)
```swift
var method: BackgroundRemovalMethod = .vision
```
- ✓ Free, on-device
- ✓ No internet required
- ✓ Fast
- ✗ Only works with people wearing clothes
- ✗ Lower quality

### WithoutBG API
```swift
var method: BackgroundRemovalMethod = .api
var apiBaseURL: String = "http://localhost:8000"
```
- ✓ Better quality
- ✓ Works with flat lay photos
- ✓ More accurate edge detection
- ✗ Requires server
- ✗ Requires internet connection
- ✗ Slower (network latency)

## Troubleshooting

### "Connection refused" error

**Check 1:** Is the server running?
```bash
curl http://localhost:8000/health
```

**Check 2:** Are you using the right IP on physical device?
```bash
# Find your Mac's IP
ipconfig getifaddr en0
```

**Check 3:** Firewall blocking port 8000?
```bash
# On macOS, temporarily allow:
# System Settings → Network → Firewall → Options → Add port 8000
```

### "WithoutBG not available" in logs

The backend will work without WithoutBG installed, but quality will be lower.

To install WithoutBG properly:
```bash
pip install withoutbg
```

If installation fails, it may need additional dependencies. Check the WithoutBG repo.

### App hangs during processing

Check Xcode console for error messages. Common issues:
- Wrong API URL
- Server not running
- Network not reachable

### HTTP not allowed on iOS

Make sure Info.plist has:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Note:** For production, use HTTPS instead!

## Next Steps

Once you've tested and are happy with the results:

1. **Deploy the backend** to a production server (Railway, Render, etc.)
2. **Update apiBaseURL** to your production URL
3. **Add HTTPS** for security
4. **Implement tiered approach:**
   - Free users: Vision framework
   - Premium users: WithoutBG API

## Console Logs to Watch

When testing, watch for these logs in Xcode:

**Vision method:**
```
Processing image with Vision framework...
Successfully removed background
```

**API method:**
```
Sending image to API: http://localhost:8000/remove-background
API Response status: 200
Successfully received processed image from API
```

**Errors:**
```
API Error: The Internet connection appears to be offline.
API Error response: {"detail":"Error processing image: ..."}
```
