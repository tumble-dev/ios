//
//  CustomProgressView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/19/22.
//

import SwiftUI
import Combine

struct CustomProgressIndicator: View {
    let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    let timing: Double
    
    @State private var rotation: Double = 0
    
    let frame: CGSize
    let primaryColor: Color
    
    init(color: Color = .primary, size: CGFloat = 20, speed: Double = 0.05) {
        timing = speed
        timer = Timer.publish(every: timing, on: .main, in: .common).autoconnect()
        frame = CGSize(width: size, height: size)
        primaryColor = color
    }
    
    var body: some View {
        Circle()
            .trim(from: 0.1, to: 0.9)
            .stroke(primaryColor, lineWidth: 4)
            .frame(width: frame.width, height: frame.height)
            .rotationEffect(Angle(degrees: rotation))
            .onReceive(timer, perform: { _ in
                withAnimation {
                    rotation += 45
                }
            })
    }
}

struct CustomProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        CustomProgressIndicator()
    }
}

