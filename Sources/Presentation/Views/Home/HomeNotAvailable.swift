//
//  HomeNotAvailable.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-04.
//

import SwiftUI

struct HomeNotAvailable: View {
    var body: some View {
        VStack(alignment: .center) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Text(NSLocalizedString("Everything looks good for this week", comment: ""))
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.onBackground)
                    .padding(.trailing, Spacing.small)
                
                Text(NSLocalizedString("Looks like you don't have any classes or exams in the coming week. Yay!", comment: ""))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.onBackground)
                    .padding(.trailing, 25)
            }
            Spacer()
            Image("WomanLounging")
                .resizable()
                .scaledToFit()
                .frame(width: getRect().width - 40, height: getRect().width - 80)
                .padding(.bottom, 20)
        }
    }
}

struct HomeNotAvailable_Previews: PreviewProvider {
    static var previews: some View {
        HomeNotAvailable()
    }
}
