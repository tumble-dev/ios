//
//  SchoolPill.swift
//  Tumble
//
//  Created by Adis Veletanlic on 4/19/23.
//

import SwiftUI

struct SchoolPill: View, Pill {
    
    var id: UUID = UUID()

    let school: School
    
    var title: String
    
    var icon: Image
    
    @Binding var selectedSchool: School?
    
    
    init(school: School, selectedSchool: Binding<School?>) {
        self._selectedSchool = selectedSchool
        self.title = school.domain.uppercased()
        self.icon = school.logo
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
                    .foregroundColor(isSelected() ? .onPrimary : .onSurface)
            }
            .padding(2)
        })
        .buttonStyle(PillStyle(color: isSelected() ? .primary : .surface))
        .padding(Spacing.extraSmall)
    }
    
    var fontSize: CGFloat {
        isSelected() ? 18 : 16
    }
    
    func isSelected() -> Bool {
        return selectedSchool == school
    }
}
