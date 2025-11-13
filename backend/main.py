from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from PIL import Image
import io
import logging
from typing import Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="ClothesAI Background Removal API")

# Add CORS middleware to allow browser access from file:// URLs and other origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)

# Try to import withoutbg, fall back gracefully if not available
try:
    from withoutbg import remove_background as withoutbg_remove
    WITHOUTBG_AVAILABLE = True
    logger.info("WithoutBG loaded successfully")
except ImportError:
    WITHOUTBG_AVAILABLE = False
    logger.warning("WithoutBG not available, using fallback method")

# Try to import rembg, fall back gracefully if not available
try:
    from rembg import remove as rembg_remove, new_session
    REMBG_AVAILABLE = True
    logger.info("Rembg loaded successfully")
except ImportError:
    REMBG_AVAILABLE = False
    logger.warning("Rembg not available")

# Available models for rembg
REMBG_MODELS = {
    "u2net": "General purpose (default)",
    "u2net_cloth_seg": "Clothing segmentation (best for clothes)",
    "isnet-general-use": "High quality general purpose",
    "silueta": "Fast & lightweight (43MB)"
}


def remove_bg_withoutbg(image: Image.Image) -> Image.Image:
    """Remove background using WithoutBG library."""
    # Process with WithoutBG - it accepts PIL Image directly
    result_image = withoutbg_remove(image)

    # Create white background
    white_bg = Image.new('RGB', result_image.size, (255, 255, 255))

    # Composite the result onto white background
    if result_image.mode == 'RGBA':
        white_bg.paste(result_image, (0, 0), result_image)
    else:
        white_bg.paste(result_image, (0, 0))

    return white_bg


def remove_bg_rembg(image: Image.Image, model: str = "u2net") -> Image.Image:
    """Remove background using Rembg library with selectable models."""
    # Create a session with the specified model
    session = new_session(model)

    # Process with Rembg - it accepts PIL Image and returns RGBA
    result_image = rembg_remove(image, session=session)

    # Create white background
    white_bg = Image.new('RGB', result_image.size, (255, 255, 255))

    # Composite the result onto white background
    if result_image.mode == 'RGBA':
        white_bg.paste(result_image, (0, 0), result_image)
    else:
        white_bg.paste(result_image, (0, 0))

    return white_bg


def remove_bg_fallback(image: Image.Image) -> Image.Image:
    """Fallback method - just add white background."""
    # Create white background
    white_bg = Image.new('RGB', image.size, (255, 255, 255))

    # Paste original image
    if image.mode == 'RGBA':
        white_bg.paste(image, (0, 0), image)
    else:
        white_bg.paste(image, (0, 0))

    return white_bg


@app.get("/")
async def root():
    """Health check endpoint."""
    return {
        "status": "ok",
        "service": "ClothesAI Background Removal API",
        "methods": {
            "rembg": REMBG_AVAILABLE,
            "withoutbg": WITHOUTBG_AVAILABLE,
            "fallback": True
        },
        "rembg_models": REMBG_MODELS if REMBG_AVAILABLE else {}
    }


@app.post("/remove-background")
async def remove_background_endpoint(
    file: UploadFile = File(...),
    method: str = "rembg",
    model: str = "u2net_cloth_seg",
    format: str = "png"
):
    """
    Remove background from uploaded image.

    Args:
        file: Image file to process
        method: Background removal method (rembg, withoutbg, fallback), default: rembg
        model: Model to use (only for rembg method), default: u2net_cloth_seg
        format: Output format (png or jpeg), default: png

    Returns:
        Processed image with white background
    """
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")

        # Read image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))

        logger.info(f"Processing image: {file.filename}, size: {image.size}, mode: {image.mode}, method: {method}, model: {model}")

        # Remove background based on selected method
        if method == "rembg":
            if not REMBG_AVAILABLE:
                raise HTTPException(status_code=400, detail="Rembg is not available. Install with: pip install rembg")
            if model not in REMBG_MODELS:
                raise HTTPException(status_code=400, detail=f"Invalid model. Available models: {list(REMBG_MODELS.keys())}")
            logger.info(f"Using Rembg with model: {model}")
            result_image = remove_bg_rembg(image, model=model)
        elif method == "withoutbg":
            if not WITHOUTBG_AVAILABLE:
                raise HTTPException(status_code=400, detail="WithoutBG is not available. Install with: pip install withoutbg")
            logger.info("Using WithoutBG for background removal")
            result_image = remove_bg_withoutbg(image)
        elif method == "fallback":
            logger.info("Using fallback method (simple white background)")
            result_image = remove_bg_fallback(image)
        else:
            raise HTTPException(status_code=400, detail=f"Invalid method. Available: rembg, withoutbg, fallback")

        # Convert to requested format
        output = io.BytesIO()
        if format.lower() == 'jpeg' or format.lower() == 'jpg':
            result_image.save(output, format='JPEG', quality=95)
            media_type = "image/jpeg"
        else:
            result_image.save(output, format='PNG')
            media_type = "image/png"

        output.seek(0)

        logger.info(f"Successfully processed image: {file.filename}")

        return StreamingResponse(output, media_type=media_type)

    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")


@app.get("/health")
async def health_check():
    """Detailed health check."""
    return {
        "status": "healthy",
        "version": "2.0.0",
        "methods": {
            "rembg": REMBG_AVAILABLE,
            "withoutbg": WITHOUTBG_AVAILABLE,
            "fallback": True
        },
        "rembg_models": REMBG_MODELS if REMBG_AVAILABLE else {},
        "default_method": "rembg" if REMBG_AVAILABLE else ("withoutbg" if WITHOUTBG_AVAILABLE else "fallback"),
        "default_model": "u2net_cloth_seg"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
