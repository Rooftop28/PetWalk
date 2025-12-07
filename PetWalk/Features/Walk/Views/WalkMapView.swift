//
//  WalkMapView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import SwiftUI
import MapKit

struct WalkMapView: UIViewRepresentable {
    // 核心依赖：位置服务和宠物图片
    @ObservedObject var locationManager: LocationManager
    var petImage: UIImage?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // 我们自己管理 Annotation，所以关掉系统的（或者系统留着做对比也可以，这里为了不重叠，先关掉）
        // mapView.showsUserLocation = true 
        mapView.showsUserLocation = false
        
        // 跟踪模式：跟随用户并显示方向
        // mapView.userTrackingMode = .followWithHeading
        
        // 添加长按手势 (Debug 模式下模拟移动)
        #if DEBUG
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
        #endif
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 1. 绘制轨迹 (Polyline)
        updateRoutePolyline(on: uiView)
        
        // 2. 更新宠物位置 (无论是真实定位还是模拟定位)
        updatePetAnnotation(on: uiView)
        
        // 3. 移动视角跟随
        if let location = locationManager.currentLocation {
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            uiView.setRegion(region, animated: true)
        }
    }
    
    private func updatePetAnnotation(on mapView: MKMapView) {
        guard let location = locationManager.currentLocation else { return }
        
        // 查找现有的宠物 Annotation
        var petAnnotation: MKPointAnnotation?
        for annotation in mapView.annotations {
            if let point = annotation as? MKPointAnnotation, point.title == "Pet" {
                petAnnotation = point
                break
            }
        }
        
        if let annotation = petAnnotation {
            // 平滑移动 (简单设置 coordinate 也会有动画效果，如果需要更平滑可以使用 UIView 动画)
            UIView.animate(withDuration: 0.5) {
                annotation.coordinate = location.coordinate
            }
        } else {
            // 如果还没有，创建一个新的
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = location.coordinate
            newAnnotation.title = "Pet"
            mapView.addAnnotation(newAnnotation)
        }
    }
    
    private func updateRoutePolyline(on mapView: MKMapView) {
        // 简单处理：移除旧线，画新线 (生产环境可优化为只添加新点)
        mapView.removeOverlays(mapView.overlays)
        
        let coordinates = locationManager.routeCoordinates
        guard coordinates.count > 1 else { return }
        
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
    }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: WalkMapView
        
        init(_ parent: WalkMapView) {
            self.parent = parent
        }
        
        #if DEBUG
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // 震动反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            print("🐛 Debug: 模拟移动到 \(coordinate.latitude), \(coordinate.longitude)")
            parent.locationManager.simulateMove(to: coordinate)
        }
        #endif
        
        // 渲染轨迹线
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(named: "AppGreenMain") ?? .systemGreen // 使用 App 主色调
                renderer.lineWidth = 6
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // 自定义用户图标 (宠物头像)
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // 以前是判断 is MKUserLocation，现在改为判断我们自己的 Annotation
            if let point = annotation as? MKPointAnnotation, point.title == "Pet" {
                let identifier = "PetUserLocation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                
                // 设置宠物图片
                if let petImage = parent.petImage {
                    // 压缩图片大小，否则地图上会显示一张巨图
                    let size = CGSize(width: 50, height: 50)
                    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                    
                    // 绘制圆形裁剪
                    let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
                    path.addClip()
                    petImage.draw(in: CGRect(origin: .zero, size: size))
                    
                    // 加个白色描边让它在地图上更明显
                    UIColor.white.setStroke()
                    path.lineWidth = 4
                    path.stroke()
                    
                    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    annotationView?.image = resizedImage
                } else {
                    // 没有宠物图时，用默认图标或者爪印
                    annotationView?.image = UIImage(systemName: "pawprint.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
                }
                
                // 加点阴影
                annotationView?.layer.shadowColor = UIColor.black.cgColor
                annotationView?.layer.shadowOpacity = 0.3
                annotationView?.layer.shadowOffset = CGSize(width: 0, height: 2)
                annotationView?.layer.shadowRadius = 4
                
                return annotationView
            }
            return nil
        }
    }
}

