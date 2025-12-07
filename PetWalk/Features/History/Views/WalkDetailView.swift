//
//  WalkDetailView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import SwiftUI
import MapKit

struct WalkDetailView: View {
    let record: WalkRecord
    
    // 动态计算地图区域
    var region: MKCoordinateRegion {
        guard let route = record.route, !route.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
        
        let lats = route.map { $0.lat }
        let lons = route.map { $0.lon }
        
        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5, longitudeDelta: (maxLon - minLon) * 1.5)
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    var body: some View {
        ZStack {
            // 背景色铺满
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 1. 地图轨迹回放
                    if let route = record.route, !route.isEmpty {
                        StaticRouteMapView(route: route)
                            .frame(height: 300)
                            .cornerRadius(20)
                            .padding(.horizontal)
                            .shadow(radius: 5)
                    } else {
                        ZStack {
                            Color.gray.opacity(0.1)
                            Text("本次遛狗未记录轨迹")
                                .foregroundColor(.gray)
                        }
                        .frame(height: 200)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                    
                // 2. 详细数据
                HStack(spacing: 20) {
                    let durationText = record.duration == 0 ? "< 1 min" : "\(record.duration) min"
                    DetailStatBox(title: "距离", value: String(format: "%.2f km", record.distance), icon: "map.fill")
                    DetailStatBox(title: "时长", value: durationText, icon: "clock.fill")
                }
                .padding(.horizontal)
                    
                    // 3. 照片回顾
                    if let imageName = record.imageName, !imageName.isEmpty {
                        VStack(alignment: .leading) {
                            Text("回忆照片")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if let image = loadLocalImage(named: imageName) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .padding(.horizontal)
                                    .shadow(radius: 5)
                            }
                        }
                    }
                    
                    // 4. 心情
                    HStack {
                        Text("心情:")
                            .font(.headline)
                        Image(systemName: record.mood == "happy" ? "face.smiling.fill" : (record.mood == "tired" ? "zzz" : "pawprint.fill"))
                            .foregroundColor(record.mood == "happy" ? .orange : (record.mood == "tired" ? .blue : .green))
                            .font(.title)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
        }
        // 强制使用 Light Mode 配色 (如果 App 整体设计不支持深色模式)
        .preferredColorScheme(.light)
        .navigationTitle(record.date)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 辅助加载图片
    func loadLocalImage(named name: String) -> UIImage? {
        if let assetImage = UIImage(named: name) { return assetImage }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) { return image }
        return nil
    }
}

// 静态地图组件
struct StaticRouteMapView: UIViewRepresentable {
    let route: [RoutePoint]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        mapView.isUserInteractionEnabled = true 
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 清理旧覆盖物
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)
        
        let coordinates = route.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
        guard !coordinates.isEmpty else { return }
        
        // 画线
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        uiView.addOverlay(polyline)
        
        // 添加起点和终点
        let start = MKPointAnnotation()
        start.coordinate = coordinates.first!
        start.title = "起点"
        
        let end = MKPointAnnotation()
        end.coordinate = coordinates.last!
        end.title = "终点"
        
        uiView.addAnnotation(start)
        uiView.addAnnotation(end)
        
        // 设置缩放区域 (增加一点 padding)
        let rect = polyline.boundingMapRect
        uiView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(named: "AppGreenMain") ?? .systemGreen
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct DetailStatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appGreenMain)
            VStack(alignment: .leading) {
                Text(title).font(.caption).foregroundColor(.gray)
                Text(value).font(.headline)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
