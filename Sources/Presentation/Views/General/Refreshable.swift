//
//  Refreshable.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-28.
//

import Foundation
import SwiftUI

struct Refreshable: View {
    var coordinateSpaceName: String
    var onRefresh: () -> Void
    
    @State var needRefresh: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: .named(coordinateSpaceName)).midY > 50 {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if geo.frame(in: .named(coordinateSpaceName)).maxY < 10 {
                Spacer()
                    .onAppear {
                        if needRefresh {
                            needRefresh = false
                            onRefresh()
                        }
                    }
            }
            HStack {
                Spacer()
                if needRefresh {
                    CustomProgressIndicator()
                }
                Spacer()
            }
        }.padding(.top, -50)
    }
}
