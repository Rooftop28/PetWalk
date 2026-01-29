//
//  SupabaseConfig.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/29.
//

import Foundation

enum SupabaseConfig {
    /// ⚠️ 请在 Supabase 控制台获取 Project URL 并替换此处
    static let projectURL = URL(string: "https://bwwnrgocprhuofqylobj.supabase.co")!
    
    /// ⚠️ 请在 Supabase 控制台获取 Anon Public Key 并替换此处
    static let apiKey = "sb_publishable_YCa8hD1RiVtfSPGrPC3eHQ_jCamJkE4"
    
    /// 检查配置是否有效
    static var isValid: Bool {
        return projectURL.absoluteString != "YOUR_SUPABASE_URL" && apiKey != "YOUR_SUPABASE_ANON_KEY"
    }
}
