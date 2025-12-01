//
//  SpeechBubbleView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/1.
//

import SwiftUI

struct SpeechBubbleView: View {
    var text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.appBrown)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appYellowBlob.opacity(0.4))
            .background(Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                Image(systemName: "arrowtriangle.down.fill")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 14))
                    .offset(x: -10, y: 18)
                , alignment: .bottomLeading
            )
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
