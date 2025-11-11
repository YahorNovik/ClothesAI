#!/usr/bin/env python3
"""
Simple test script for the background removal API.
"""
import requests
import sys
from pathlib import Path

def test_api(image_path: str, output_path: str = "result.png", api_url: str = "http://localhost:8000"):
    """
    Test the background removal API.

    Args:
        image_path: Path to input image
        output_path: Path to save processed image
        api_url: Base URL of the API
    """
    # Check if image exists
    if not Path(image_path).exists():
        print(f"Error: Image not found: {image_path}")
        return False

    print(f"Testing API at: {api_url}")
    print(f"Input image: {image_path}")

    # Test health endpoint
    try:
        response = requests.get(f"{api_url}/health")
        print(f"\n✓ Health check: {response.json()}")
    except Exception as e:
        print(f"\n✗ Health check failed: {e}")
        return False

    # Test background removal
    try:
        print(f"\nUploading image...")
        with open(image_path, 'rb') as f:
            files = {'file': f}
            response = requests.post(f"{api_url}/remove-background", files=files)

        if response.status_code == 200:
            # Save result
            with open(output_path, 'wb') as f:
                f.write(response.content)
            print(f"✓ Success! Result saved to: {output_path}")
            return True
        else:
            print(f"✗ Error: {response.status_code}")
            print(response.text)
            return False

    except Exception as e:
        print(f"✗ Request failed: {e}")
        return False


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_api.py <image_path> [output_path] [api_url]")
        print("\nExample:")
        print("  python test_api.py test.jpg")
        print("  python test_api.py test.jpg result.png")
        print("  python test_api.py test.jpg result.png http://192.168.1.100:8000")
        sys.exit(1)

    image_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else "result.png"
    api_url = sys.argv[3] if len(sys.argv) > 3 else "http://localhost:8000"

    success = test_api(image_path, output_path, api_url)
    sys.exit(0 if success else 1)
