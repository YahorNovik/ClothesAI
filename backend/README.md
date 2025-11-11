# ClothesAI Background Removal Backend

Local backend server for removing backgrounds from clothing photos using WithoutBG.

## Setup

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Run the Server

```bash
python main.py
```

Or using uvicorn directly:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The server will start on `http://localhost:8000`

## API Endpoints

### `POST /remove-background`

Remove background from an image.

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body: `file` (image file)
- Query params: `format` (optional, default: "png")

**Example using curl:**

```bash
curl -X POST "http://localhost:8000/remove-background" \
  -F "file=@/path/to/image.jpg" \
  --output result.png
```

**Response:**
- Content-Type: `image/png` or `image/jpeg`
- Body: Processed image with white background

### `GET /`

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "service": "ClothesAI Background Removal API",
  "withoutbg_available": true
}
```

### `GET /health`

Detailed health check.

**Response:**
```json
{
  "status": "healthy",
  "withoutbg_available": true,
  "version": "1.0.0"
}
```

## Testing the API

### Test from command line:

```bash
# Upload and process an image
curl -X POST "http://localhost:8000/remove-background" \
  -F "file=@test_image.jpg" \
  --output processed.png
```

### Test with Python:

```python
import requests

url = "http://localhost:8000/remove-background"
files = {"file": open("test_image.jpg", "rb")}

response = requests.post(url, files=files)

with open("result.png", "wb") as f:
    f.write(response.content)
```

## iOS App Configuration

Update the iOS app to point to your local server:

1. **For iOS Simulator:** Use `http://localhost:8000`
2. **For Physical Device:** Use your Mac's local IP (e.g., `http://192.168.1.100:8000`)

To find your Mac's IP:
```bash
ipconfig getifaddr en0
```

## Deployment Options

### Option 1: Railway.app
1. Push to GitHub
2. Connect to Railway
3. Deploy automatically

### Option 2: Render.com
1. Push to GitHub
2. Create new Web Service on Render
3. Set build command: `pip install -r requirements.txt`
4. Set start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

### Option 3: DigitalOcean/AWS/GCP
Deploy as a Docker container or directly on a VM.

## Troubleshooting

### WithoutBG not installing?
The server will fall back to a simple white background method if WithoutBG is not available.

### Port already in use?
Change the port in `main.py`:
```python
uvicorn.run(app, host="0.0.0.0", port=8001)  # Use different port
```

### CORS issues?
Add CORS middleware if needed:
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
```
