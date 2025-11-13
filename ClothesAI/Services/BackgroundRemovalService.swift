import UIKit
import CoreImage
import Vision

enum BackgroundRemovalMethod {
    case vision      // Apple Vision Framework (on-device, free)
    case api         // WithoutBG API (server-based, better quality)
}

class BackgroundRemovalService {
    static let shared = BackgroundRemovalService()

    // Configuration - change this to switch between methods
    var method: BackgroundRemovalMethod = .api  // Using API (WithoutBG) for best quality

    // Server URL Configuration
    // For iOS Simulator: use "http://localhost:8000"
    // For Physical Device: use your Mac's IP, e.g., "http://192.168.1.100:8000"
    // To find your Mac's IP: Run 'ipconfig getifaddr en0' in Terminal
    var apiBaseURL: String = "http://localhost:8000"

    private init() {}

    /// Removes the background from an image and replaces it with white
    func removeBackground(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        switch method {
        case .vision:
            removeBackgroundVision(from: image, completion: completion)
        case .api:
            removeBackgroundAPI(from: image, completion: completion)
        }
    }

    // MARK: - Vision Framework Method

    private func removeBackgroundVision(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        // Create a request to segment the person/object
        let request = VNGeneratePersonSegmentationRequest { request, error in
            guard error == nil else {
                print("Error in background removal: \(error!.localizedDescription)")
                completion(nil)
                return
            }

            guard let result = request.results?.first as? VNPixelBufferObservation else {
                completion(nil)
                return
            }

            // Process the mask and apply white background
            let maskedImage = self.applyMask(result.pixelBuffer, to: cgImage)
            completion(maskedImage)
        }

        // Set quality level based on subscription tier
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        // Perform the request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform segmentation: \(error)")
                completion(nil)
            }
        }
    }

    private func applyMask(_ maskBuffer: CVPixelBuffer, to image: CGImage) -> UIImage? {
        let ciImage = CIImage(cgImage: image)
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)

        // Scale mask to match image size
        let scaleX = ciImage.extent.width / maskImage.extent.width
        let scaleY = ciImage.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Create white background
        let whiteColor = CIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let whiteBackground = CIImage(color: whiteColor).cropped(to: ciImage.extent)

        // Blend the original image with white background using the mask
        let blendFilter = CIFilter(name: "CIBlendWithMask")
        blendFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blendFilter?.setValue(whiteBackground, forKey: kCIInputBackgroundImageKey)
        blendFilter?.setValue(scaledMask, forKey: kCIInputMaskImageKey)

        guard let outputImage = blendFilter?.outputImage else {
            return nil
        }

        // Convert back to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Fallback method for devices that don't support person segmentation
    func removeBackgroundFallback(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        // Simple approach: use subject lifting (iOS 16+) or return original
        DispatchQueue.global(qos: .userInitiated).async {
            // For iOS 16+, we can use the built-in subject lifting
            if #available(iOS 16.0, *) {
                // This would use the subject lifting API
                // For now, return the original image with white background composite
                let processedImage = self.addWhiteBackground(to: image)
                DispatchQueue.main.async {
                    completion(processedImage)
                }
            } else {
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
    }

    private func addWhiteBackground(to image: UIImage) -> UIImage? {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, true, image.scale)
        defer { UIGraphicsEndImageContext() }

        // Fill with white
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        // Draw the image on top
        image.draw(at: .zero)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - API Method (WithoutBG)

    private func removeBackgroundAPI(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        // Resize image if too large (max 2000px on longest side)
        let resizedImage = resizeImageIfNeeded(image, maxDimension: 2000)

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to JPEG data")
            completion(nil)
            return
        }

        print("📤 Image size: \(resizedImage.size.width)x\(resizedImage.size.height), data: \(imageData.count / 1024)KB")

        let url = URL(string: "\(apiBaseURL)/remove-background")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60 // 60 second timeout

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("📡 Sending image to API: \(url)")
        print("⏱️ Timeout set to 60 seconds")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ API Connection Error: \(error.localizedDescription)")
                    print("📍 Server URL: \(self.apiBaseURL)")
                    print("💡 Troubleshooting:")
                    print("   • Make sure backend server is running: python backend/main.py")
                    print("   • For iOS Simulator: use http://localhost:8000")
                    print("   • For Physical Device: use your Mac's IP (e.g., http://192.168.1.100:8000)")
                    print("   • Check that both devices are on the same WiFi network")
                    completion(nil)
                    return
                }

                guard let data = data else {
                    print("No data received from API")
                    completion(nil)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("API Response status: \(httpResponse.statusCode)")

                    if httpResponse.statusCode != 200 {
                        if let errorString = String(data: data, encoding: .utf8) {
                            print("API Error response: \(errorString)")
                        }
                        completion(nil)
                        return
                    }
                }

                guard let resultImage = UIImage(data: data) else {
                    print("❌ Failed to create image from API response")
                    print("   Response data size: \(data.count) bytes")
                    completion(nil)
                    return
                }

                print("✅ Successfully received processed image from API")
                print("   Result size: \(resultImage.size.width)x\(resultImage.size.height)")
                completion(resultImage)
            }
        }

        task.resume()
    }

    // MARK: - Helper Methods

    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxCurrentDimension = max(size.width, size.height)

        // If image is already smaller than max, return as is
        if maxCurrentDimension <= maxDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let scale = maxDimension / maxCurrentDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        print("📏 Resizing image from \(size.width)x\(size.height) to \(newSize.width)x\(newSize.height)")

        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}
