//
//  BobbleSlider.swift
//  BobbleSlider
//
//  Created by Tanvi Nabar on 10/29/19.
//  Copyright © 2019 Tanvi Nabar. All rights reserved.
//

import UIKit

class BobbleSlider: UISlider {
    private var noOfTicks: Int = 9
    private var sliderTrackHeight: CGFloat = 6.0
    private var tickWidth: CGFloat = 1.0
    private var tickHeight: CGFloat = 2.0
    private var selectedTrackColor: UIColor = UIColor(hexString: "#dcd0ff") // Lavender
    private var unselectedTrackColor: UIColor = UIColor.lightGray
    private var selectedTickColor: UIColor = UIColor.black.withAlphaComponent(0.64)
    private var unselectedTickColor: UIColor = UIColor.black.withAlphaComponent(0.64)
    
    // Value of each interval between ticks
    var stepValue: Float {
        return self.maximumValue / Float(noOfTicks + 1)
    }
    
    /// Calculates and returns the current center position of the slider's thumb
    var thumbCenter: CGPoint {
        let trackRect: CGRect = self.trackRect(forBounds: frame)
        let thumbRect: CGRect = self.thumbRect(forBounds: bounds, trackRect: trackRect, value: value)
        
        return CGPoint(x: thumbRect.midX, y: thumbRect.midY)
    }
    
    init(noOfTicks: Int? = nil,
         sliderTrackHeight: CGFloat? = nil,
         tickWidth: CGFloat? = nil,
         tickHeight: CGFloat? = nil,
         selectedTrackColor: UIColor? = nil,
         unselectedTrackColor: UIColor? = nil,
         selectedTickColor: UIColor? = nil,
         unselectedTickColor: UIColor? = nil) {
        super.init(frame: .zero)
        
        self.noOfTicks = noOfTicks ?? self.noOfTicks
        self.sliderTrackHeight = sliderTrackHeight ?? self.sliderTrackHeight
        self.tickWidth = tickWidth ?? self.tickWidth
        self.tickHeight = tickHeight ?? self.tickHeight
        self.selectedTrackColor = selectedTrackColor ?? self.selectedTrackColor
        self.unselectedTrackColor = unselectedTrackColor ?? self.unselectedTrackColor
        self.selectedTickColor = selectedTickColor ?? self.selectedTickColor
        self.unselectedTickColor = unselectedTickColor ?? self.unselectedTickColor
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        self.setTrackImages(fromRect: rect)
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let point: CGPoint = CGPoint(x: bounds.minX, y: bounds.midY - self.sliderTrackHeight / 2)
        return CGRect(origin: point, size: CGSize(width: bounds.width, height: self.sliderTrackHeight))
    }
    
    /// Adds colored images with ticks, for the filled and unfilled sections of the slider. Also
    /// sets the thumb image.
    /// - Parameter innerRect: the drawing area for the slider
    private func setTrackImages(fromRect innerRect: CGRect) {
        let spaceBetweenTicks: CGFloat = CGFloat(innerRect.size.width - CGFloat(self.noOfTicks) * self.tickWidth) / CGFloat(self.noOfTicks + 1)
        
        // In order to show rounded ends, we need to add some space before the slider image starts.
        // The radius for this rounded end (line cap) is half the thickness of the line (sliderTrackHeight)
        let leftForBezels: CGPoint = CGPoint(x: self.sliderTrackHeight / 2.0, y: self.sliderTrackHeight / 2.0)
        let rightForBezels: CGPoint = CGPoint(x: innerRect.width - self.sliderTrackHeight / 2.0, y: self.sliderTrackHeight / 2.0)
        
        // The ticks are achieved using a dashed line. Since a dashed line starts with a dash, we
        // add some offset (phase) to not show the first dash (Look up CGContext's setLineDash)
        let leftForTicks: CGPoint = CGPoint(x: spaceBetweenTicks, y: self.sliderTrackHeight / 2.0)
        let rightForTicks: CGPoint = CGPoint(x: innerRect.width, y: self.sliderTrackHeight / 2.0)
        
        // Draw background image for filled side with ticks
        let selectedSideWithTicks: UIImage? = UIGraphicsImageRenderer(size: CGSize(width: innerRect.width, height: self.sliderTrackHeight)).image { (imageContext) in
            imageContext.cgContext.setStrokeColor(self.selectedTrackColor.cgColor)
            imageContext.cgContext.setLineWidth(self.sliderTrackHeight)
            imageContext.cgContext.setLineCap(.round)
            
            imageContext.cgContext.move(to: leftForBezels)
            imageContext.cgContext.addLine(to: rightForBezels)
            imageContext.cgContext.strokePath()
            
            imageContext.cgContext.setStrokeColor(self.selectedTickColor.cgColor)
            imageContext.cgContext.setLineWidth(self.tickHeight)
            imageContext.cgContext.setLineDash(phase: 0.0, lengths: [self.tickWidth, spaceBetweenTicks])
            
            imageContext.cgContext.move(to: leftForTicks)
            imageContext.cgContext.addLine(to: rightForTicks)
            imageContext.cgContext.drawPath(using: .stroke)
        }
        
        // Draw background image for unfilled side with ticks
        let unselectedSideWithTicks: UIImage? = UIGraphicsImageRenderer(size: CGSize(width: innerRect.width, height: self.sliderTrackHeight)).image { (imageContext) in
            imageContext.cgContext.setLineWidth(self.sliderTrackHeight)
            imageContext.cgContext.setLineCap(.round)
            imageContext.cgContext.setStrokeColor(self.unselectedTrackColor.cgColor)
            
            imageContext.cgContext.move(to: leftForBezels)
            imageContext.cgContext.addLine(to: rightForBezels)
            imageContext.cgContext.strokePath()

            imageContext.cgContext.setStrokeColor(self.unselectedTickColor.cgColor)
            imageContext.cgContext.setLineWidth(self.tickHeight)
            imageContext.cgContext.setLineDash(phase: 0.0, lengths: [self.tickWidth, spaceBetweenTicks])
            
            imageContext.cgContext.move(to: leftForTicks)
            imageContext.cgContext.addLine(to: rightForTicks)
            imageContext.cgContext.strokePath()
        }
        
        self.setMinimumTrackImage(selectedSideWithTicks?.resizableImage(withCapInsets: .zero, resizingMode: .tile), for: .normal)
        self.setMaximumTrackImage(unselectedSideWithTicks, for: .normal)
        
        // Set thumb image. The image we set has padding on the top and the bottom, so that its easier for the user to drag the thumb.
        // Since it is clear, it won't be visible to the user.
        let thumbImage: UIImage? = UIImage(named: "slider-handle-padding")?.withTintColor(UIColor.clear)
        self.setThumbImage(thumbImage, for: .normal)
        self.setThumbImage(thumbImage, for: .highlighted)
    }
}
