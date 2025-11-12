# ClothesAI Background Removal Backend

Local backend server for removing backgrounds from clothing photos using multiple AI models:
- **Rembg** (Recommended) - Multiple models including clothing-specific segmentation
- **WithoutBG** - High-quality background removal
- **Fallback** - Simple white background (no AI processing)

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

Remove background from an image with customizable methods and models.

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body: `file` (image file)
- Query params:
  - `method` (optional, default: "rembg") - Options: `rembg`, `withoutbg`, `fallback`
  - `model` (optional, default: "u2net_cloth_seg") - Only for rembg method
  - `format` (optional, default: "png") - Options: `png`, `jpeg`

**Available Rembg Models:**
- `u2net_cloth_seg` - **Best for clothing** (default)
- `u2net` - General purpose
- `isnet-general-use` - High quality general purpose
- `silueta` - Fast & lightweight (43MB)

**Example using curl:**

```bash
# Using rembg with clothing-specific model (default)
curl -X POST "http://localhost:8000/remove-background?method=rembg&model=u2net_cloth_seg" \
  -F "file=@/path/to/image.jpg" \
  --output result.png

# Using WithoutBG
curl -X POST "http://localhost:8000/remove-background?method=withoutbg" \
  -F "file=@/path/to/image.jpg" \
  --output result.png

# Compare different models
curl -X POST "http://localhost:8000/remove-background?method=rembg&model=u2net" \
  -F "file=@shirt.jpg" \
  --output result_u2net.png
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
  "methods": {
    "rembg": true,
    "withoutbg": true,
    "fallback": true
  },
  "rembg_models": {
    "u2net": "General purpose (default)",
    "u2net_cloth_seg": "Clothing segmentation (best for clothes)",
    "isnet-general-use": "High quality general purpose",
    "silueta": "Fast & lightweight (43MB)"
  }
}
```

### `GET /health`

Detailed health check.

**Response:**
```json
{
  "status": "healthy",
  "version": "2.0.0",
  "methods": {
    "rembg": true,
    "withoutbg": true,
    "fallback": true
  },
  "rembg_models": {...},
  "default_method": "rembg",
  "default_model": "u2net_cloth_seg"
}
```

## Testing the API

### Web Interface

Open `test.html` in your browser to test the API with a visual interface:

```bash
# Simply open the file in your browser
open test.html  # macOS
# Or double-click test.html in Finder
```

The web interface will automatically check the server connection and allow you to:
- **Choose between methods**: Rembg, WithoutBG, or Fallback
- **Select models**: For rembg, choose from 4 different models
- Upload and process images
- See before/after comparison
- Download the result

**Tip:** Try different models on the same image to compare results!

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

# Using rembg with clothing-specific model (recommended for clothes)
url = "http://localhost:8000/remove-background?method=rembg&model=u2net_cloth_seg"
files = {"file": open("shirt.jpg", "rb")}

response = requests.post(url, files=files)

with open("result.png", "wb") as f:
    f.write(response.content)
```

### Compare Models:

Test the same image with different models to find the best one:

```bash
# Test all rembg models on the same image
for model in u2net_cloth_seg u2net isnet-general-use silueta; do
  curl -X POST "http://localhost:8000/remove-background?method=rembg&model=$model" \
    -F "file=@shirt.jpg" \
    --output "result_${model}.png"
  echo "Processed with $model"
done

# Compare with WithoutBG
curl -X POST "http://localhost:8000/remove-background?method=withoutbg" \
  -F "file=@shirt.jpg" \
  --output result_withoutbg.png
```

**Which model to use?**
- **u2net_cloth_seg**: Best for clothing items (shirts, pants, dresses)
- **isnet-general-use**: Best overall quality, but slower
- **silueta**: Fastest processing, good for simple backgrounds
- **u2net**: Good general purpose fallback

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

### Rembg not installing?
If you have issues installing rembg:
```bash
# Try installing with specific version
pip install "rembg>=2.0.50"

# Or install without optional dependencies
pip install rembg --no-deps
pip install onnxruntime pillow numpy
```

The server will automatically fall back to WithoutBG or the fallback method if rembg is not available.

### WithoutBG not installing?
The server will fall back to rembg or the simple fallback method if WithoutBG is not available.

### First run is slow?
Rembg downloads model files on first use. This is normal:
- **u2net_cloth_seg**: ~65MB download
- **u2net**: ~176MB download
- **isnet-general-use**: ~175MB download
- **silueta**: ~43MB download

Models are cached in `~/.u2net/` and won't be downloaded again.

### Port already in use?
Change the port in `main.py`:
```python
uvicorn.run(app, host="0.0.0.0", port=8001)  # Use different port
```

### CORS issues?
CORS is enabled by default to allow the web interface to work when opened as a file.

**Note:** In production, you should restrict `allow_origins` to specific domains instead of `["*"]`.
