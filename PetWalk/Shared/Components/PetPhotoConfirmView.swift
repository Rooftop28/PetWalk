//
//  PetPhotoConfirmView.swift
//  PetWalk
//

import SwiftUI

struct PetPhotoConfirmView: View {
    @ObservedObject private var viewModel = PetViewModel.shared
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Text("预览抠图效果")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appBrown)
                    
                    Spacer()
                    
                    if let image = viewModel.pendingImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 280, maxHeight: 350)
                            .shadow(color: .black.opacity(0.1), radius: 15, y: 8)
                            .rotationEffect(.degrees(rotationAngle))
                            .animation(.spring(response: 0.3), value: rotationAngle)
                    }
                    
                    Spacer()
                    
                    // 旋转按钮
                    Button {
                        rotationAngle += 90
                        viewModel.rotatePendingImage()
                        rotationAngle = 0
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rotate.right.fill")
                            Text("旋转 90°")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appBrown)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                    }
                    
                    // 操作按钮
                    HStack(spacing: 16) {
                        Button {
                            viewModel.cancelPendingImage()
                        } label: {
                            Text("重新选择")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white)
                                .foregroundColor(.gray)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        }
                        
                        Button {
                            viewModel.confirmPendingImage()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("确认使用")
                            }
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.appGreenMain)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.appGreenMain.opacity(0.3), radius: 8, y: 4)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.cancelPendingImage()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview {
    PetPhotoConfirmView()
}
