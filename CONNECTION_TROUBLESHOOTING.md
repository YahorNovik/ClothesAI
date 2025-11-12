# Backend Connection Troubleshooting Guide

## Problem: "Cannot connect to server" Error

The iOS app needs to connect to the Python backend server, but the connection is failing.

## Quick Diagnosis

### Are you using iOS Simulator or Physical Device?

#### ✅ iOS Simulator
- **Solution:** Use `http://localhost:8000`
- Simulator runs on your Mac, so localhost works fine

#### ⚠️ Physical iPhone/iPad
- **Problem:** `localhost` refers to the device itself, not your Mac
- **Solution:** Use your Mac's IP address instead

## Step-by-Step Fix

### Step 1: Find Your Mac's IP Address

Open Terminal on your Mac and run:
```bash
ipconfig getifaddr en0
```

This will output something like: `192.168.1.100`

### Step 2: Update the iOS App

Open `ClothesAI/Services/BackgroundRemovalService.swift` and change line 20:

```swift
// For Simulator:
var apiBaseURL: String = "http://localhost:8000"

// For Physical Device (replace with YOUR IP):
var apiBaseURL: String = "http://192.168.1.100:8000"
```

### Step 3: Start the Backend Server

```bash
cd backend
source venv/bin/activate  # or: . venv/bin/activate
python main.py
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

### Step 4: Verify Connection

Option 1 - Open the web test interface:
```bash
open backend/test.html
```

Option 2 - Test with curl:
```bash
curl http://localhost:8000/health
```

Should return: `{"status":"ok","withoutbg_available":true}`

## Common Issues

### 1. Server Not Starting
```
Error: No module named 'fastapi'
```
**Fix:** Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Connection Refused (Physical Device)
**Causes:**
- Mac firewall blocking port 8000
- Device not on same WiFi network
- Wrong IP address

**Fix:**
1. Check devices are on same WiFi
2. Allow Python through firewall:
   - System Preferences → Security & Privacy → Firewall → Firewall Options
   - Add Python and allow incoming connections

### 3. Connection Works but No Background Removal
**Check Xcode console logs:**
```swift
// Look for:
"Sending image to API: http://..."
"API Response status: 200"
"Successfully received processed image from API"
```

**If you see:**
```
"API Error: Could not connect to the server"
```
- Server is not reachable at the configured URL

### 4. WithoutBG Not Available
Server logs show:
```
WARNING: WithoutBG library not available
```

**This is OK** - The server will use a fallback method (adds white background)

To get better results, install WithoutBG:
```bash
pip install withoutbg
```

## Testing Checklist

- [ ] Backend server is running (`python main.py`)
- [ ] Server shows "Uvicorn running on http://0.0.0.0:8000"
- [ ] Health check works: `curl http://localhost:8000/health`
- [ ] Correct URL configured in BackgroundRemovalService.swift
  - [ ] Simulator: `http://localhost:8000`
  - [ ] Physical device: `http://YOUR_MAC_IP:8000`
- [ ] Both devices on same WiFi (physical device only)
- [ ] Mac firewall allows connections (physical device only)

## Advanced: Dynamic Configuration

For switching between Simulator and Device easily, you could use a settings screen in the app or read from a configuration file. This would let you change the server URL without recompiling.

## Still Having Issues?

1. Check Xcode console for detailed error messages
2. Check backend server logs for incoming requests
3. Try the web interface (`backend/test.html`) to verify server works
4. Use `curl -v http://YOUR_URL/health` to test connectivity
