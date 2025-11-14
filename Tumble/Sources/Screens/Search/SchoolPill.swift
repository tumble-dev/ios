//
//  SchoolPill.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI

protocol Pill: Identifiable, Hashable {
    var title: String { get }
    var icon: Image { get }
    var id: UUID { get }
}

extension Pill {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct SchoolPill: View, Pill {
    var id: UUID = .init()

    let school: School
    
    var title: String
    
    var icon: Image
    
    @Binding var selectedSchool: School?
    
    init(school: School, selectedSchool: Binding<School?>) {
        _selectedSchool = selectedSchool
        title = school.id.uppercased()
        icon = Image(school.logoPath)
        self.school = school
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                if isSelected() {
                    selectedSchool = nil
                } else {
                    selectedSchool = school
                }
            }
        }, label: {
            HStack {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: fontSize, height: fontSize)
                    .cornerRadius(50)
                Text(title)
                    .font(.system(size: fontSize, weight: isSelected() ? .semibold : .regular))
                    .foregroundColor(isSelected() ? .tumbleOnPrimary : .tumbleOnSurface)
            }
            .padding(2)
        })
        .buttonStyle(PillStyle(color: isSelected() ? .tumblePrimary : .tumbleSurface))
    }
    
    var fontSize: CGFloat {
        isSelected() ? 18 : 16
    }
    
    func isSelected() -> Bool {
        return selectedSchool == school
    }
}
