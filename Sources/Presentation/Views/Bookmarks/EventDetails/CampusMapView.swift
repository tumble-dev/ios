//
//  CampusMapView.swift
//  App
//
//  Created by Timur Ramazanov on 27.09.2024.
//

import SwiftUI
import SwiftSVG
import RealmSwift
import UIKit

struct CampusMapView: UIViewRepresentable {
    let selectedLocations: [String]
    let schoolDomain: String
    let schoolColor: String
    
    func makeUIView(context: Context) -> UIView {
        let svgView = UIView()
        
        // Load the SVG from the asset catalog
        if let svgData = NSDataAsset(name: "campus-\(schoolDomain)")?.data {
            // Load the SVG into the UIView
            CALayer(svgData: svgData) { svgLayer in
                
                // Add the layer to the view
                svgView.layer.addSublayer(svgLayer)
                
                // Scale the SVG to fit the screen width
                scaleSVGToFullWidth(svgLayer: svgLayer, view: svgView)
                
                // Highlight the selected buildings when the view is created
                highlightBuildings(svgLayer: svgLayer, view: svgView)
            }
        }

        return svgView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    /// Makes `CALayer` with campus map SVG take the whole screen width
    func scaleSVGToFullWidth(svgLayer: CALayer, view: UIView) {
        let screenWidth = UIScreen.main.bounds.width
        
        // SVG original viewport dimensions (100 x 130)
        let svgWidth: CGFloat = 100
        
        // Calculate the scale factor to make the SVG take full-width
        let scaleFactor = screenWidth / svgWidth
        
        // Apply the scale transformation while maintaining the aspect ratio
        svgLayer.transform = CATransform3DMakeScale(scaleFactor, scaleFactor, 1)
    }
    
    /// Changes selected shapes fill to university or accent color
    func highlightBuildings(svgLayer: SVGLayer, view: UIView) {
        // Get svg map sublayers with individual buildings
        guard let mapSublayers = svgLayer.sublayers?.first?.sublayers else { return }
        
        // Reset all building fill colors first
        let isDarkMode = view.traitCollection.userInterfaceStyle == .dark
        for sublayer in mapSublayers {
            if let buildingLayer = sublayer as? CAShapeLayer {
                buildingLayer.fillColor = isDarkMode ? UIColor.darkGray.cgColor : UIColor.lightGray.cgColor
            }
        }
        
        for buildingId in selectedLocations {
            if let buildingLayer = mapSublayers.first(where: { $0.name?.lowercased() == "building-\(buildingId.lowercased())" }) as? CAShapeLayer {
                if let schoolColor = UIColor(named: schoolColor.capitalized) {
                    buildingLayer.fillColor = schoolColor.cgColor
                } else {
                    buildingLayer.fillColor = UIColor(resource: .accent).cgColor
                }
            }
        }
    }
}
