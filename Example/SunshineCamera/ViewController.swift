//
//  ViewController.swift
//  SunshineCamera
//
//  Created by GarenChen on 09/28/2017.
//  Copyright (c) 2017 GarenChen. All rights reserved.
//

import UIKit
import SunshineCamera

class ViewController: UIViewController {
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 200, width: UIScreen.main.bounds.size.width, height: 300))
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .lightGray
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.addSubview(imageView)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let ctr = PhotoCaptureController.initiate(photoShouldSaveToAlbum: false, cropFrame: CGRect(x: 0 , y: UIScreen.main.bounds.size.height / 2 - 125, width: UIScreen.main.bounds.size.width, height: 250), cropDescription: "请讲身份证放进方框内", complitionHandler: { [weak self] (image) in
            self?.imageView.image = image
        })
        
        present(ctr, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

