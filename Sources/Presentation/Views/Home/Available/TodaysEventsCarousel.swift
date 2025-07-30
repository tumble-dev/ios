//
//  TodaysEventsCarousel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-03.
//

import SwiftUI

struct TodaysEventsCarousel: View {
    @Binding var swipedCards: Int
    @Binding var weekEventCards: [WeekEventCardModel]
    @State private var showWiggleAnimation = true
    
    var body: some View {
        ZStack {
            if weekEventCards.isEmpty {
                Text(NSLocalizedString("No events for today", comment: ""))
                    .font(.system(size: 18))
                    .foregroundColor(.onBackground)
            } else {
                ForEach(weekEventCards.indices.reversed(), id: \.self) { index in
                    CarouselCard(
                        event: weekEventCards[index].event,
                        index: index,
                        eventsForToday: weekEventCards,
                        swipedCards: $swipedCards,
                        showWiggleAnimation: index == 0 && showWiggleAnimation
                    )
                    .frame(height: 160)
                    .contentShape(Rectangle())
                    .offset(x: weekEventCards[index].offset + 5)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                onChanged(value: value, index: index)
                            }
                            .onEnded { value in
                                onEnded(value: value, index: index)
                            }
                    )
                }
            }
        }
        if weekEventCards.count > 1 {
            resetButton
        }
    }
        
    var resetButton: some View {
        HStack {
            Spacer()
            Button(action: resetCards, label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.onPrimary)
                    .padding(15)
                    .background(Color.primary)
                    .clipShape(Circle())
                
            })
            .cornerRadius(30)
            .buttonStyle(ScalingButtonStyle())
        }
        .padding(.top, Spacing.small)
    }
    
    func resetCards() {
        for index in weekEventCards.indices {
            withAnimation(.spring()) {
                weekEventCards[index].offset = 0
                swipedCards = 0
            }
        }
    }
    
    func onChanged(value: DragGesture.Value, index: Int) {
        if value.translation.width < 0 && weekEventCards.count > 1 {
            weekEventCards[index].offset = value.translation.width
        }
        if showWiggleAnimation {
            showWiggleAnimation = false
        }
    }

    
    func onEnded(value: DragGesture.Value, index: Int) {
        withAnimation {
            if -value.translation.width > getRect().width / 3 {
                weekEventCards[index].offset = -getRect().width
                swipedCards += 1
            } else {
                weekEventCards[index].offset = 0
            }
        }
        if swipedCards == weekEventCards.count {
            resetCards()
        }
    }
}

private struct CarouselCard: View {
    let event: Event
    let index: Int
    let eventsForToday: [WeekEventCardModel]
    @Binding var swipedCards: Int
    var showWiggleAnimation: Bool
    
    var body: some View {
        HStack {
            VerboseEventButtonLabel(event: event)
                .frame(
                    width: getCardWidth(index: index),
                    height: getCardHeight(index: index)
                )
                .offset(x: getCardOffset(index: index))
                .rotationEffect(.init(degrees: getCardRotation(index: index)))
                .if(showWiggleAnimation, transform: { view in
                    view.modifier(WiggleModifier())
                })
                .if(index != eventsForToday.count - 1, transform: { view in
                    view.shadow(
                        color: Color.black.opacity(0.1),
                        radius: (index - swipedCards) <= 2 ? 2 : 0, x: 5, y: 2
                    )
                })
            Spacer()
        }
    }
    
    func getCardRotation(index: Int) -> Double {
        let boxWidth = Double(getRect().width / 3)
        let offset = Double(eventsForToday[index].offset)
        let angle: Double = 8
        return (offset / boxWidth) * angle
    }
    
    func getCardHeight(index: Int) -> CGFloat {
        let height: CGFloat = 160
        let cardHeight = (index - swipedCards) <= 3 ? CGFloat(index - swipedCards) * 35 : 30
        return height - cardHeight
    }
    
    func getCardWidth(index: Int) -> CGFloat {
        let boxWidth = (getRect().width - 60)
        return boxWidth
    }
    
    func getCardOffset(index: Int) -> CGFloat {
        return (index - swipedCards) <= 2 ? CGFloat(index - swipedCards) * 13 : 0
    }
}

struct WiggleModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isAnimating ? -2 : 0))
            .offset(x: isAnimating ? -15 : 0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.2).repeatCount(3, autoreverses: true).delay(0.2)) {
                    isAnimating.toggle()
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(Animation.easeInOut(duration: 0.2).repeatCount(3, autoreverses: true).delay(0.2)) {
                        isAnimating.toggle()
                    }
                }
            }
    }
}
