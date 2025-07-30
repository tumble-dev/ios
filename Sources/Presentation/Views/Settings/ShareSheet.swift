//
//  ShareSheet.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-06-06.
//

import SwiftUI
import UniformTypeIdentifiers

struct ShareSheet: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    let websiteLink: String = "app.tumbleforkronox.com"
    let appStoreLink: String = "https://apps.apple.com/se/app/tumble-for-kronox/id1617642864?l=en"
    
    @State private var qrCodeImage: UIImage? = nil
    
    var body: some View {
        VStack {
            DraggingPill()
            SheetTitle(title: NSLocalizedString("Share the app", comment: ""))
            VStack (alignment: .center) {
                Image("AppIconOpaque")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                copyButton
                VStack (alignment: .center) {
                    Text(NSLocalizedString("Scan QR Code", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.onSurface)
                        .padding(.bottom, Spacing.medium / 2)
                    if let qrCodeImage = qrCodeImage {
                        Image(uiImage: qrCodeImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .cornerRadius(10)
                    } else {
                        CustomProgressIndicator()
                    }
                }
                .padding()
                .background(Color.background)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.onSurface.opacity(0.5), lineWidth: 2))
            }
            .padding(.top, Spacing.large)
            Spacer()
        }
        .overlay(
            CloseCoverButton(onClick: { dismiss() })
            ,alignment: .topTrailing
        )
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                let image = generateQRCode(from: appStoreLink, in: colorScheme)
                DispatchQueue.main.async {
                    self.qrCodeImage = image
                }
            }
        }
    }
    
    var copyButton: some View {
        Button(action: copyToClipBoard, label: {
            HStack {
                VStack (alignment: .leading, spacing: 0) {
                    Text(NSLocalizedString("Copy link", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.onSurface)
                        .padding(.bottom, Spacing.medium / 2)
                    Text(websiteLink)
                        .font(.system(size: 12))
                        .foregroundColor(.onSurface.opacity(0.7))
                }
                Spacer()
                Image(systemName: "doc.on.doc")
                    .foregroundColor(Color("OnSurface"))
            }
            .padding(14)
        })
        .buttonStyle(OutlinedButtonStyle())
        .padding(.horizontal, 45)
        .padding(.vertical, 25)
    }
    
    func copyToClipBoard() {
        HapticsController.triggerHapticMedium()
        UIPasteboard.general.setValue(
            websiteLink,
            forPasteboardType: UTType.plainText.identifier
        )
    }

}

struct ShareSheet_Previews: PreviewProvider {
    static var previews: some View {
        ShareSheet()
    }
}
