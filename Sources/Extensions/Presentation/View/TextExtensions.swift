//
//  ViewFontExtensions.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-28.
//

import Foundation
import SwiftUI

extension Text {
    func sheetTitle() -> some View {
        font(.system(size: 18, weight: .semibold))
            .foregroundColor(.onBackground)
            .padding(.top, 15)
    }
    
    func bodyInstructions() -> some View {
        font(.system(size: 14, weight: .medium))
    }
    
    func infoBodyMedium(opacity: Double = 1.0) -> some View {
        font(.system(size: 20))
            .fontWeight(.semibold)
            .foregroundColor(.onBackground.opacity(opacity))
            .padding(.bottom, 25)
            .padding([.leading, .trailing], Spacing.medium)
    }
    
    func infoHeaderSmall() -> some View {
        font(.system(size: 24))
            .fontWeight(.semibold)
            .foregroundColor(.onBackground)
            .padding(.bottom, 25)
            .padding([.leading, .trailing], 15)
    }
    
    func infoHeaderMedium() -> some View {
        font(.system(size: 34, weight: .black))
            .foregroundColor(.onBackground)
    }
    
    func programmeTitle() -> some View {
        font(.system(size: 18, weight: .semibold))
            .multilineTextAlignment(.leading)
            .padding(.bottom, 10)
    }
    
    func programmeSubTitle() -> some View {
        font(.system(size: 14))
            .multilineTextAlignment(.leading)
    }
    
    func searchResultsField() -> some View {
        font(.system(size: 18, weight: .semibold))
            .foregroundColor(.onBackground)
            .padding([.leading, .top], 20)
            .padding(.bottom, 10)
    }
    
    func dayHeader() -> some View {
        font(.system(size: 20, weight: .semibold))
            .padding(.trailing, 10)
    }
}
