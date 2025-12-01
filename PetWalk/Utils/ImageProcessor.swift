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
    
    /// 输入一张图片，返回去除背景后的图片 (iOS 17+)
    static func removeBackground(from image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // 1. 创建 Vision 请求
        let request = VNGenerateForegroundInstanceMaskRequest()
        
        // 2. 创建处理句柄
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            // 3. 执行请求
            try handler.perform([request])
            
            // 4. 获取结果
            guard let result = request.results?.first else {
                print("Vision 未检测到主体")
                return nil
            }
            
            // 5. 核心魔法：直接生成蒙版后的图像
            // croppedToInstancesExtent: true 表示会自动把空白边缘裁掉，只保留狗狗主体
            let maskedPixelBuffer = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )
            
            // 6. 将 CVPixelBuffer 转换为 UIImage
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
}
