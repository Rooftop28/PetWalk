//
//  PhoneConnector.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/2.
//

import Foundation
import WatchConnectivity
import SwiftUI

class PhoneConnector: NSObject, WCSessionDelegate, ObservableObject {
    // 发布收到的图片给 Watch UI
    @Published var receivedImage: UIImage?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // --- 接收文件的回调 ---
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("⌚️ 手表收到了文件！")
        
        // 文件在 file.fileURL，这是一个临时路径，必须马上拷走或读取
        if let data = try? Data(contentsOf: file.fileURL),
           let image = UIImage(data: data) {
            
            // 回到主线程更新 UI
            DispatchQueue.main.async {
                self.receivedImage = image
            }
        }
    }
    
    // --- WCSessionDelegate 必须实现的方法 ---
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
