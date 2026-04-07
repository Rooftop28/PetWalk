//
//  PetIdentityView.swift
//  PetWalk
//
//  Created by User on 2026/01/30.
//

import SwiftUI
import PhotosUI

struct PetIdentityView: View {
    @Binding var name: String
    @Binding var ownerNickname: String
    @Binding var profile: PetProfile
    
    @ObservedObject private var petViewModel = PetViewModel.shared
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("第一步：填写基础档案")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.appBrown)
                
                // Pet Photo
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack {
                            if petViewModel.isProcessing {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .overlay {
                                        VStack(spacing: 8) {
                                            ProgressView()
                                            Text("抠图中…")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                            } else if let image = petViewModel.currentPetImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.appGreenMain, lineWidth: 3)
                                    )
                                    .shadow(color: .appGreenMain.opacity(0.3), radius: 8, y: 4)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .overlay {
                                        VStack(spacing: 6) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(.appBrown.opacity(0.4))
                                            Text("选择照片")
                                                .font(.caption)
                                                .foregroundColor(.appBrown.opacity(0.6))
                                        }
                                    }
                            }
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        petViewModel.selectAndProcessImage(from: newItem)
                    }
                    
                    Text("选择宠物照片，自动抠图生成形象")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Name Input
                VStack(alignment: .leading) {
                    Text("它的名字")
                        .font(.headline)
                        .foregroundColor(.gray)
                    TextField("例如：旺财", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 8)
                }
                
                // Owner Nickname
                VStack(alignment: .leading) {
                    Text("它怎么称呼你？")
                        .font(.headline)
                        .foregroundColor(.gray)
                    TextField("例如：爸爸、妈妈、长官", text: $ownerNickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Gender
                VStack(alignment: .leading) {
                    Text("性别")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        ForEach(PetGender.allCases) { gender in
                            Button {
                                withAnimation {
                                    profile.gender = gender
                                }
                            } label: {
                                HStack {
                                    Text(gender.icon)
                                    Text(gender.rawValue)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(profile.gender == gender ? Color.appGreenMain : Color.gray.opacity(0.1))
                                .foregroundColor(profile.gender == gender ? .white : .primary)
                                .cornerRadius(20)
                            }
                        }
                    }
                }
                
                // Breed
                VStack(alignment: .leading) {
                    Text("品种 (Breed)")
                        .font(.headline)
                        .foregroundColor(.gray)
                    TextField("例如：柯基、金毛...", text: $profile.breed)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Birthday
                VStack(alignment: .leading) {
                    Text("生日/年龄")
                        .font(.headline)
                        .foregroundColor(.gray)
                    DatePicker("", selection: $profile.birthday, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                    
                    Text("当前阶段：\(profile.ageGroup.rawValue) (\(profile.ageGroup.description))")
                        .font(.caption)
                        .foregroundColor(.appBrown)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding()
        .sheet(isPresented: $petViewModel.showConfirmation) {
            PetPhotoConfirmView()
                .interactiveDismissDisabled()
        }
    }
}
