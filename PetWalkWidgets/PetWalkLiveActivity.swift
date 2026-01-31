//
//  PetWalkLiveActivity.swift
//  PetWalk
//
//  Created by Cursor AI Assistant on 2026/01/31.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PetWalkLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetWalkAttributes.self) { context in
            // Lock Screen / Banner View
            PetWalkLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(Color.white)
                
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded UI
                
                // Left: Pet Animation
                DynamicIslandExpandedRegion(.leading) {
                    HStack(alignment: .center, spacing: 4) {
                        petIcon(for: context.state)
                            .font(.system(size: 34))
                        
                        // Mood Bubble
                        if !context.state.petMood.isEmpty {
                            Text(moodEmoji(for: context.state.petMood))
                                .font(.caption)
                                .offset(y: -10)
                        }
                    }
                    .dynamicIsland(verticalPlacement: .belowIfTooWide)
                }
                
                // Right: Main Stat (Distance)
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("\(String(format: "%.2f", context.state.distance))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        Text("km")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .dynamicIsland(verticalPlacement: .belowIfTooWide)
                }
                
                // Bottom: Stats Grid
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        StatView(title: "Duration", value: formatDuration(context.state.duration))
                        
                        Divider()
                            .frame(height: 30)
                        
                        StatView(title: "Speed", value: String(format: "%.1f km/h", context.state.currentSpeed))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
                
            } compactLeading: {
                // MARK: - Compact Leading
                HStack(spacing: 2) {
                    Image(systemName: context.state.isMoving ? "hare.fill" : "tortoise.fill")
                        .foregroundColor(.brown)
                }
            } compactTrailing: {
                // MARK: - Compact Trailing
                Text("\(String(format: "%.2f", context.state.distance))km")
                    .foregroundColor(.green)
                    .font(.caption.bold())
            } minimal: {
                // MARK: - Minimal
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.brown)
            }
        }
    }
    
    // Helper Views
    
    @ViewBuilder
    func petIcon(for state: PetWalkAttributes.ContentState) -> some View {
        if state.isMoving {
            Image(systemName: "dog.fill")
                .foregroundColor(.brown)
                .symbolEffect(.bounce, options: .repeating, value: state.isMoving)
        } else {
            Image(systemName: "dog")
                .foregroundColor(.gray)
        }
    }
    
    func moodEmoji(for mood: String) -> String {
        switch mood {
        case "happy": return "🎵"
        case "tired": return "💦"
        case "excited": return "✨"
        default: return "🐶"
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct PetWalkLockScreenView: View {
    let context: ActivityViewContext<PetWalkAttributes>
    
    var body: some View {
        HStack {
            // Pet Avatar
            Image(systemName: context.state.isMoving ? "figure.run" : "figure.walk")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .padding()
                .background(Circle().fill(Color.orange.opacity(0.2)))
            
            VStack(alignment: .leading) {
                Text(context.attributes.petName)
                    .font(.headline)
                Text(context.state.isMoving ? "Running..." : "Paused")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(String(format: "%.2f", context.state.distance)) km")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(context.state.currentSpeed > 0 ? "\(String(format: "%.1f", context.state.currentSpeed)) km/h" : "--")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.trailing)
        }
        .padding()
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
        }
    }
}
