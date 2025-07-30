//
//  HomeError.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-04.
//

import SwiftUI

struct HomeError: View {
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 20) {
                Text(NSLocalizedString("Something went wrong", comment: ""))
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.onBackground)
                    .padding(.trailing, 10)
                
                Text(NSLocalizedString("We experienced an issue when trying to find your schedules. Try again later", comment: ""))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.onBackground)
                    .padding(.trailing, 25)
            }
            Spacer()
            Image("WomanArmsUp")
                .resizable()
                .scaledToFit()
                .frame(width: getRect().width - 40, height: getRect().width - 80)
                .padding(.bottom, 20)
        }
    }
}

struct HomeError_Previews: PreviewProvider {
    static var previews: some View {
        HomeError()
    }
}
