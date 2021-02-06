//
//  BobbleSliderContainer.swift
//  BobbleSlider
//
//  Created by Tanvi Nabar on 04/11/19.
//  Copyright © 2019 Tanvi Nabar. All rights reserved.
//

import UIKit

protocol SliderThemeProvider: AnyObject {
    var noOfTicks: Int { get }
    var sliderTrackHeight: CGFloat { get }
    var tickWidth: CGFloat { get }
    var tickHeight: CGFloat { get }
    var thumbThemeColor: UIColor { get }
    var trackThemeColor: UIColor { get }
    var floatingThumbImage: UIImage? { get }
    var trackColor: (selected: UIColor, unselected: UIColor) { get }
}

extension SliderThemeProvider {
    var noOfTicks: Int {
        return 9
    }
    var sliderTrackHeight: CGFloat {
        return 6.0
    }
    var tickWidth: CGFloat {
        return 1.0
    }
    var tickHeight: CGFloat {
        return 2.0
    }
    var thumbThemeColor: UIColor {
        return bubbleSliderDefaults.thumbThemeColor
    }
    var trackThemeColor: UIColor {
        return bubbleSliderDefaults.trackThemeColor
    }
    var floatingThumbImage: UIImage? {
        return bubbleSliderDefaults.floatingImage
    }
    var trackColor: (selected: UIColor, unselected: UIColor) {
        return (UIColor(hexString: "#dcd0ff"), UIColor.lightGray)
    }
    var tickColor: (selected: UIColor, unselected: UIColor) {
        return (UIColor.black.withAlphaComponent(0.64), UIColor.black.withAlphaComponent(0.64))
    }
}

protocol BobbleSliderContainerDelegate: AnyObject {
    func sliderValueDidChange(to newValue: Int)
}

fileprivate typealias bubbleSliderDefaults = BobbleSliderContainer.Defaults

class BobbleSliderContainer: UIView {
    struct Defaults {
        static let thumbThemeColor: UIColor = UIColor.purple
        static let trackThemeColor: UIColor = UIColor(hexString: "#dcd0ff") // Lavender
        static let floatingImage: UIImage? = UIImage(named: "heart_image")
        fileprivate static let heartImageHeight: CGFloat = 32.0
        fileprivate static let distanceBetweenHeartAndThumbImage: CGFloat = 8.0
        fileprivate static let thumbImageHeight: CGFloat = 14.0
        fileprivate static let sliderValueLabelWidth: CGFloat = 50.0
        fileprivate static let distanceBetweenSliderAndLabel: CGFloat = 20.0
        fileprivate static let angleOfRotationForHeart: CGFloat = CGFloat.pi / 6.0
    }
    
    weak var themeProvider: SliderThemeProvider?
    weak var delegate: BobbleSliderContainerDelegate?
    
    var selectionFeedbackGenerator: UISelectionFeedbackGenerator?
    private var tapGesture: UITapGestureRecognizer?
    
    /// Whether the user is currently interacting with the slider or not
    private var isInteracting: Bool = false {
        didSet {
            self.setStartSlidingLabelVisibility()
            self.tapGesture?.isEnabled = !self.isInteracting
        }
    }
    
    /// The Y position of the heart when it is floating above the slider
    lazy private var floatingHeartVerticalOffsetFromTrack: CGFloat = {
        return (bubbleSliderDefaults.heartImageHeight + bubbleSliderDefaults.thumbImageHeight) / 2 + bubbleSliderDefaults.distanceBetweenHeartAndThumbImage
    }()
    
    /// The floating heart view on top of the slider, that chases the thumb
    lazy private var floatingThumbImageView: UIImageView = {
        let floatingThumbImageView: UIImageView = UIImageView()
        floatingThumbImageView.contentMode = .scaleAspectFit
        floatingThumbImageView.translatesAutoresizingMaskIntoConstraints = false
        
        return floatingThumbImageView
    }()
    
    /// If the thumb image of the slider has a shadow, it cannot be moved to the edges of the slider.
    /// Instead, we set the thumb image of the slider without a shadow, while the image with shadow is
    /// superimposed on top of it
    lazy private var sliderThumbWithShadow: UIImageView = {
        let sliderThumbWithShadow: UIImageView = UIImageView(image: UIImage(named: "thumb_small"))
        sliderThumbWithShadow.contentMode = .scaleAspectFit
        sliderThumbWithShadow.translatesAutoresizingMaskIntoConstraints = false
        sliderThumbWithShadow.layer.shadowColor = UIColor.black.cgColor
        sliderThumbWithShadow.layer.shadowOpacity = 0.5
        sliderThumbWithShadow.layer.shadowOffset = CGSize(width: 0, height: 2)
        sliderThumbWithShadow.layer.shadowRadius = 2.0
        
        return sliderThumbWithShadow
    }()
    
    lazy private var bobbleSlider: BobbleSlider = {
        let bobbleSlider: BobbleSlider = BobbleSlider(frame: .zero)
        bobbleSlider.minimumValue = 0.0
        bobbleSlider.maximumValue = 100.0
        bobbleSlider.value = 0.0
        
        bobbleSlider.translatesAutoresizingMaskIntoConstraints = false
        
        return bobbleSlider
    }()
    
    /// The current value of the slider
    lazy private var sliderValueLabel: UILabel = {
        let label: UILabel = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor.darkGray
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    /// Start Sliding label that toggles based on slider's value (Show on value=0, else dont show)
    lazy private var startSlidingLabel: UILabel = {
        let label: UILabel = UILabel(frame: .zero)
        label.text = "START SLIDING →"
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textColor = UIColor.darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        
        return label
    }()
    
    /// Based on the current value of the slider, return the new center for the heart
    /// image. If the value is 0, and the user is not interacting, the heart is inline with
    /// the slider. Else, the heart floats above the current slider position
    private func getCalculatedCenterForHeart() -> CGPoint {
        var bubbleSliderThumbCenter: CGPoint = bobbleSlider.thumbCenter
        
        if self.isInteracting || Int(bobbleSlider.value) != 0 {
            bubbleSliderThumbCenter.y = bubbleSliderThumbCenter.y - self.floatingHeartVerticalOffsetFromTrack
        }
        
        return bubbleSliderThumbCenter
    }
    
    /// the Start Sliding label should be visible only if the value is 0 and the user isn't
    /// interacting with it
    private func setStartSlidingLabelVisibility() {
        if self.isInteracting == false && bobbleSlider.value == 0 {
            self.startSlidingLabel.isHidden = false
        } else {
            self.startSlidingLabel.isHidden = true
        }
    }
    
    private var roundedOffToStepValue: Float {
        let roundedStep: Float = roundf(bobbleSlider.value / bobbleSlider.stepValue)
        
        return roundedStep * bobbleSlider.stepValue
    }
    
    var shouldAllowToSlide: Bool = true {
        didSet {
            self.isUserInteractionEnabled = self.shouldAllowToSlide
            
            if self.shouldAllowToSlide {
                // Value can be changed, so prepare the Haptic Feedback engine.
                if self.selectionFeedbackGenerator == nil {
                    self.selectionFeedbackGenerator = UISelectionFeedbackGenerator()
                }
                
                self.selectionFeedbackGenerator?.prepare()
            } else {
                self.selectionFeedbackGenerator = nil
            }
        }
    }
    
    private var storedValueForHaptic: Int = -1 {
        didSet {
            if oldValue != -1,
                oldValue != self.storedValueForHaptic,
                self.storedValueForHaptic % 10 == 0 {
                self.selectionFeedbackGenerator?.selectionChanged()
                self.selectionFeedbackGenerator?.prepare()
            }
        }
    }
    
    convenience init(frame: CGRect, themeProvider: SliderThemeProvider? = nil) {
        self.init(frame: frame)
        
        self.themeProvider = themeProvider
    }
    
    override private init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        // Here the defaults will be used.
        // TODO: Make it possible to setup view via Xib with provided theme
        setupView()
    }
    
    private func setupView() {
        self.removeAllSubviews()
        
        self.addSubview(self.sliderValueLabel)
        self.addSubview(self.bobbleSlider)
        self.addSubview(self.startSlidingLabel)
        self.addSubview(self.sliderThumbWithShadow)
        self.addSubview(self.floatingThumbImageView)
        
        self.sliderValueLabel.text = "\(Int(bobbleSlider.value))%"
        
        self.bobbleSlider.addTarget(self, action: #selector(sliderValueDidChange(_:forEvent:)), for: .valueChanged)
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(gestureRecognizer:)))
        tapGesture.delegate = self
        self.bobbleSlider.addGestureRecognizer(tapGesture)
        self.tapGesture = tapGesture
        
        self.floatingThumbImageView.image = self.themeProvider?.floatingThumbImage ?? UIImage(named: "heart_image")
        self.floatingThumbImageView.tintColor = self.themeProvider?.thumbThemeColor ?? bubbleSliderDefaults.thumbThemeColor
        self.sliderThumbWithShadow.tintColor = self.themeProvider?.thumbThemeColor ?? bubbleSliderDefaults.thumbThemeColor
                
        let sliderValueLabelConstraint: NSLayoutConstraint = NSLayoutConstraint(item: self.sliderValueLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: bubbleSliderDefaults.sliderValueLabelWidth)
        
        let containerConstraints: [NSLayoutConstraint] = [NSLayoutConstraint(item: self.bobbleSlider, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0),
                                                          NSLayoutConstraint(item: self.bobbleSlider, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0),
                                                          NSLayoutConstraint(item: self.bobbleSlider, attribute: .trailing, relatedBy: .equal, toItem: self.sliderValueLabel, attribute: .leading, multiplier: 1.0, constant: -5.0), NSLayoutConstraint(item: self.sliderValueLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0),
                                                          NSLayoutConstraint(item: self.sliderValueLabel, attribute: .centerY, relatedBy: .equal, toItem: self.bobbleSlider, attribute: .centerY, multiplier: 1.0, constant: 0.0),
                                                          NSLayoutConstraint(item: self.startSlidingLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0),
                                                          NSLayoutConstraint(item: self.startSlidingLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: -20.0)]
        
        let heartViewConstraints: [NSLayoutConstraint] = [NSLayoutConstraint(item: self.floatingThumbImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: bubbleSliderDefaults.heartImageHeight), NSLayoutConstraint(item: self.floatingThumbImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: bubbleSliderDefaults.heartImageHeight)]
        
        let thumbShadowConstraints: [NSLayoutConstraint] = [NSLayoutConstraint(item: self.sliderThumbWithShadow, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: bubbleSliderDefaults.thumbImageHeight), NSLayoutConstraint(item: self.sliderThumbWithShadow, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: bubbleSliderDefaults.thumbImageHeight)]
        
        self.sliderValueLabel.addConstraint(sliderValueLabelConstraint)
        self.sliderThumbWithShadow.addConstraints(thumbShadowConstraints)
        self.floatingThumbImageView.addConstraints(heartViewConstraints)
        self.addConstraints(containerConstraints)
    }
    
    /// Change the slider's value, along with the position of dependant views, like the heart and the value label
    /// - Parameter value: new value for slider
    /// - Parameter animated: whether the change needs to be animated or not
    /// - Parameter triggerDelegateCallback: the value setting might be forced externally, in which case
    /// we dont want to trigger a callback to the delegate
    public func setSliderValue(to value: Float, withAnimation animated: Bool = true, triggerDelegateCallback: Bool = true) {
        let duration: TimeInterval = animated ? 0.1 : 0.0
        
        UIView.animate(withDuration: duration) { [weak self] in
            guard let strongSelf: BobbleSliderContainer = self else { return }
            
            if value != strongSelf.bobbleSlider.value {
                strongSelf.bobbleSlider.setValue(value, animated: true)
            }
            
            if triggerDelegateCallback {
                strongSelf.delegate?.sliderValueDidChange(to: Int(strongSelf.bobbleSlider.value))
            }
            
            // Change the value of the text label to the rounded off step value
            let bubbleSliderValue: Int = Int(strongSelf.bobbleSlider.value)
            if bubbleSliderValue % 10 == 0 {
                strongSelf.sliderValueLabel.text = "\(bubbleSliderValue)%"
            }
            
            // Remove the tilt of the heart, snapping it to the new center, if needed
            strongSelf.floatingThumbImageView.transform = .identity
            
            strongSelf.floatingThumbImageView.center = strongSelf.getCalculatedCenterForHeart()
            strongSelf.sliderThumbWithShadow.center = strongSelf.bobbleSlider.thumbCenter
            strongSelf.setStartSlidingLabelVisibility()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.floatingThumbImageView.center = self.getCalculatedCenterForHeart()
        self.sliderThumbWithShadow.center = bobbleSlider.thumbCenter
    }
    
    @objc func sliderValueDidChange(_ sender: BobbleSlider, forEvent event: UIEvent) {
        if let touchEvent: UITouch = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                self.isInteracting = true
                // Get ready to animate the heart.
                UIView.animate(withDuration: 0.1) {
                    self.floatingThumbImageView.center = self.getCalculatedCenterForHeart()
                }

            case .moved:
                let potentialNewCenter: CGPoint = self.getCalculatedCenterForHeart()
                
                var angleOfRotation: CGFloat = 0.0
                var translationX: CGFloat = 0.0
                
                if self.floatingThumbImageView.center != potentialNewCenter {
                    if self.floatingThumbImageView.center.x < potentialNewCenter.x {
                        angleOfRotation = -bubbleSliderDefaults.angleOfRotationForHeart
                        translationX = -15
                    } else if self.floatingThumbImageView.center.x > potentialNewCenter.x {
                        angleOfRotation = bubbleSliderDefaults.angleOfRotationForHeart
                        translationX = 15
                    }
                    
                    // Add transform to tilt the heart in the direction opposite to the motion
                    // Move the heart along with the slider's thumb
                    // TODO: Tilt the heart back when the sliding stops, even if the user is still
                    // pressing down.
                    UIView.animate(withDuration: 0.1) {
                        self.floatingThumbImageView.transform = CGAffineTransform(translationX: translationX, y: 5.0).rotated(by: angleOfRotation)
                        self.floatingThumbImageView.center = potentialNewCenter
                    }
                    
                    // Straighten back the heart if the slider's thumb is stationary, but not released
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                        UIView.animate(withDuration: 0.1) { [weak self] in
                            guard let strongSelf: BobbleSliderContainer = self else { return }
                            if potentialNewCenter.x == strongSelf.bobbleSlider.thumbCenter.x {
                                strongSelf.floatingThumbImageView.transform = .identity
                            }
                        }
                    }
                }

            case .ended:
                self.isInteracting = false
                self.setSliderValue(to: self.roundedOffToStepValue, withAnimation: true)

            default:
                break
            }
            
            // Change the value of the text label to the rounded off step value
            let bubbleSliderValue: Int = Int(bobbleSlider.value)
            if bubbleSliderValue % 10 == 0 {
                self.sliderValueLabel.text = "\(bubbleSliderValue)%"
            }
            
            self.storedValueForHaptic = Int(bobbleSlider.value)
            
            self.sliderThumbWithShadow.center = self.bobbleSlider.thumbCenter
        }
    }
    
    /// Move the slider thumb to the tapped position
    /// - Parameter gestureRecognizer: tap gesture recognizer
    @objc func sliderTapped(gestureRecognizer: UIGestureRecognizer) {
        let pointTapped: CGPoint = gestureRecognizer.location(in: self)

        let positionOfSlider: CGPoint = self.bobbleSlider.frame.origin
        let widthOfSlider: CGFloat = self.bobbleSlider.frame.size.width
        let newValue: Float = Float((pointTapped.x - positionOfSlider.x) * CGFloat(self.bobbleSlider.maximumValue) / widthOfSlider)
        
        let roundedValue: Float = roundf(newValue / bobbleSlider.stepValue) * bobbleSlider.stepValue
        self.setSliderValue(to: roundedValue, withAnimation: true)
        
        self.isInteracting = false
    }
}

extension BobbleSliderContainer: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
