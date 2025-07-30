//
//  OnboardingView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-28.
//

import SwiftUI

struct OnBoarding: View {
    
    let finishOnBoarding: () -> Void
    
    @State private var viewedTab: Int = 0
    @State private var animateButton: Bool = true
    @State private var buttonOffset: CGFloat = 900.0
    @State private var offset: CGFloat = .zero
    @State private var shapeOffset: CGFloat = .zero

        
    init(finishOnBoarding: @escaping () -> Void) {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.primary)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.surface)
        self.finishOnBoarding = finishOnBoarding
    }
    
    var continueButton: some View {
        VStack {
            HStack {
                Button(action: finishAnimation, label: {
                    Text(NSLocalizedString("Continue", comment: ""))
                        .fontWeight(.semibold)
                        .foregroundColor(.onBackground)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(Color.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                })
                .buttonStyle(AnimatedButtonStyle())
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach(boardingScreens.indices, id: \.self) { index in
                    Circle()
                        .fill(Color.background)
                        .opacity(index == getIndex() ? 1 : 0.4)
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == getIndex() ? 1.3 : 0.85)
                        .animation(.easeInOut, value: getIndex())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 5)
        }
        .padding()
        .padding(.bottom, 20)
    }
    
    var body: some View {
        ZStack {
            // Geometric shape
            RoundedRectangle(cornerRadius: 50)
                .fill(Color.background)
                .frame(width: getRect().width - 120, height: getRect().width - 120)
                .scaleEffect(2)
                .rotationEffect(.init(degrees: 25))
                .rotationEffect(.init(degrees: getRotation()))
                .offset(y: -getRect().width + 20 + shapeOffset)
                .animation(.easeInOut, value: getIndex())

            // Onboarding Content
            OffsetPageTabView(offset: $offset) {
                HStack {
                    ForEach(boardingScreens) { screen in
                        VStack(spacing: 15) {
                            Image(screen.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: getRect().width - 160, height: getRect().width - 160)
                                .offset(y: -100)
                            VStack(alignment: .leading, spacing: 15) {
                                Text(screen.title)
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.onPrimary)
                                Text(screen.description)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.onPrimary)
                                    .padding(.trailing, 90)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .offset(y: -70)
                        }
                        .frame(width: getRect().width)
                        .frame(maxHeight: .infinity)
                    }
                }
            }
        }
        .background(
            Color.primary
                .animation(.easeInOut, value: getIndex())
        )
        .ignoresSafeArea(.container, edges: .all)
        .overlay(
            continueButton,
            alignment: .bottom
        )
        .overlay(
            CloseCoverButton(onClick: finishAnimation),
            alignment: .topTrailing
        )
    }
    
    func finishAnimation() {
        withAnimation {
                shapeOffset = UIScreen.main.bounds.height
            }
        finishOnBoarding()
    }

    
    func getRotation() -> Double {
        let process = offset / (getRect().width * 4)
        let rotation = Double(process) * 360
        return rotation
    }
    
    func getIndex() -> Int {
        let process = offset / getRect().width
        return Int(process)
    }
}
