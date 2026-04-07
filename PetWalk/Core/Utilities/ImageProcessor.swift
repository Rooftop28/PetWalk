//
//  ImageProcessor.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI
import Vision
import CoreImage.CIFilterBuiltins

struct ImageProcessor {
    
    /// 标准化图片方向，确保 CGImage 像素数据与视觉方向一致
    static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? image
    }
    
    /// 输入一张图片，返回去除背景后的图片 (iOS 17+)
    static func removeBackground(from image: UIImage) async -> UIImage? {
        let normalizedImage = normalizeOrientation(image)
        guard let cgImage = normalizedImage.cgImage else { return nil }
        
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let result = request.results?.first else {
                print("Vision 未检测到主体")
                return nil
            }
            
            let maskedPixelBuffer = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )
            
            let ciImage = CIImage(cvPixelBuffer: maskedPixelBuffer)
            let context = CIContext()
            guard let finalCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                return nil
            }
            
            return UIImage(cgImage: finalCGImage)
            
        } catch {
            print("抠图失败: \(error)")
            return nil
        }
    }
    
    /// 旋转图片指定角度（90度增量）
    static func rotate(_ image: UIImage, degrees: CGFloat) -> UIImage {
        let radians = degrees * .pi / 180
        
        var newSize = image.size
        if degrees.truncatingRemainder(dividingBy: 180) != 0 {
            newSize = CGSize(width: image.size.height, height: image.size.width)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        image.draw(in: CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height
        ))
        
        let rotated = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotated ?? image
    }
}
