//
//  PetViewModel.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI
import PhotosUI

@MainActor // 确保所有 UI 更新都在主线程
class PetViewModel: ObservableObject {
    // 当前显示的宠物图片
    @Published var currentPetImage: UIImage?
    // 是否正在处理中（显示菊花转圈）
    @Published var isProcessing = false
    
    // 图片保存的文件名
    private let fileName = "saved_pet_image.png"
    
    init() {
        // App 启动时，尝试加载之前保存的图片
        loadSavedImage()
    }
    
    // MARK: - 用户选图处理
    func selectAndProcessImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        isProcessing = true
        
        Task {
            // 1. 从相册加载原始数据
            if let data = try? await item.loadTransferable(type: Data.self),
               let originalImage = UIImage(data: data) {
                
                // 2. 调用 Vision 进行抠图
                if let processedImage = await ImageProcessor.removeBackground(from: originalImage) {
                    // 3. 更新 UI
                    self.currentPetImage = processedImage
                    // 4. 保存到本地文件
                    saveImageToDocuments(processedImage)
                }
            }
            self.isProcessing = false
        }
    }
    
    // MARK: - 本地存储逻辑 (简单版)
    
    private func saveImageToDocuments(_ image: UIImage) {
        guard let data = image.pngData() else { return }
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        try? data.write(to: url)
    }
    
    private func loadSavedImage() {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            self.currentPetImage = image
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
