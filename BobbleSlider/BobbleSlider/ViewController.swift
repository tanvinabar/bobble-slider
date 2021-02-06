//
//  ViewController.swift
//  BobbleSlider
//
//  Created by Tanvi Nabar on 24/01/21.
//

import UIKit

class ViewController: UIViewController {
    lazy var bobbleSliderView: BobbleSliderContainer = {
        let _bobbleSliderView: BobbleSliderContainer = BobbleSliderContainer(frame: .zero, themeProvider: self)
        return _bobbleSliderView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.addSubview(self.bobbleSliderView)
        self.bobbleSliderView.translatesAutoresizingMaskIntoConstraints = false
        self.bobbleSliderView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.bobbleSliderView.heightAnchor.constraint(equalToConstant: 200.0).isActive = true
        self.bobbleSliderView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20.0).isActive = true
        self.bobbleSliderView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20.0).isActive = true
    }
}

extension ViewController: SliderThemeProvider {
    
}

