//
//  PetViewModel.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI
import PhotosUI

@MainActor
class PetViewModel: ObservableObject {
    static let shared = PetViewModel()
    
    @Published var currentPetImage: UIImage?
    @Published var isProcessing = false
    
    /// 抠图完成后待确认的图片
    @Published var pendingImage: UIImage?
    /// 是否显示确认页面
    @Published var showConfirmation = false
    
    private let fileName = "saved_pet_image.png"
    
    init() {
        loadSavedImage()
    }
    
    // MARK: - 用户选图处理（抠图后进入确认流程）
    func selectAndProcessImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        isProcessing = true
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let originalImage = UIImage(data: data) {
                
                if let processedImage = await ImageProcessor.removeBackground(from: originalImage) {
                    self.pendingImage = processedImage
                    self.showConfirmation = true
                }
            }
            self.isProcessing = false
        }
    }
    
    // MARK: - 确认保存
    func confirmPendingImage() {
        guard let image = pendingImage else { return }
        currentPetImage = image
        saveImageToDocuments(image)
        WatchConnector.shared.sendImageToWatch(image)
        pendingImage = nil
        showConfirmation = false
    }
    
    /// 旋转待确认图片 90 度
    func rotatePendingImage() {
        guard let image = pendingImage else { return }
        pendingImage = ImageProcessor.rotate(image, degrees: 90)
    }
    
    // MARK: - 取消
    func cancelPendingImage() {
        pendingImage = nil
        showConfirmation = false
    }
    
    // MARK: - 本地存储
    
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
