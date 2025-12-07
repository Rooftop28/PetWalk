//
//  BlobBackgroundView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI

struct BlobBackgroundView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.appYellowBlob)
                .frame(width: 300, height: 300)
                .offset(x: -20, y: 0)
            
            Circle()
                .fill(Color.appYellowBlob.opacity(0.7))
                .frame(width: 250, height: 250)
                .offset(x: 60, y: -40)
            
            Circle()
                .fill(Color.appYellowBlob.opacity(0.6))
                .frame(width: 200, height: 200)
                .offset(x: -50, y: 80)
        }
        .blur(radius: 40) // 高斯模糊
    }
}

#Preview {
    BlobBackgroundView()
}
