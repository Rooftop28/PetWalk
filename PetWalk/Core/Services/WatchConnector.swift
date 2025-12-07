//
//  WatchConnector.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/2.
//

import Foundation
import WatchConnectivity
import UIKit

class WatchConnector: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnector()
    
    override init() {
        super.init()
        // 1. 激活会话，必须尽早做
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // 2. 发送图片的核心方法
    func sendImageToWatch(_ image: UIImage) {
        // 1. 👇 这一段 guard 代码全部删掉！
        // guard WCSession.default.isReachable else { ... }
        
        // 2. 这里的代码要保留
        print("准备处理图片数据...") // 加个日志看看
        
        guard let data = image.pngData() else {
            print("❌ 图片转 Data 失败")
            return
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("pet_transfer.png")
        
        do {
            try data.write(to: fileURL)
            WCSession.default.transferFile(fileURL, metadata: nil)
            print("🚀 已将图片放入传输队列") // 这行应该要出来了
        } catch {
            print("❌ 图片保存失败: \(error)")
        }
    }
    
    // --- WCSessionDelegate 必须实现的方法 (留空即可) ---
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}
