//
//  PhotoCaptureController.swift
//  SunshineCamera
//
//  Created by Garen on 2017/9/28.
//
//

import UIKit
import AVFoundation

public class PhotoCaptureController: UIViewController {
    
    var didFinishTakePhoto: ((UIImage) -> Void)?
    var photoShouldSaveToAlbum: Bool = true
    var cropFrame: CGRect = .zero
    var cropDescription: String?
    
    @IBOutlet weak private var photoCaptureView: PhotoCaptureView!
    @IBOutlet weak private var rightBottomButton: UIButton!
    @IBOutlet weak private var leftBottomButton: UIButton!
    @IBOutlet weak private var takePhotoButton: UIButton!
    
    public static func initiate(photoShouldSaveToAlbum: Bool = true,
                         cropFrame: CGRect = .zero,
                         cropDescription: String? = nil,
                         complitionHandler:((UIImage) -> Void)?) -> PhotoCaptureController {
        let storyboard = UIStoryboard(name: "storyboard", bundle: Bundle.currentResourceBundle)
        let controller = storyboard.instantiateViewController(withIdentifier: "PhotoCaptureController") as! PhotoCaptureController
        controller.didFinishTakePhoto = complitionHandler
        controller.photoShouldSaveToAlbum = photoShouldSaveToAlbum
        controller.cropFrame = cropFrame
        controller.cropDescription = cropDescription
        return controller
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    private var image: UIImage?
    
    private var isPhotoReady: Bool = false {
        didSet {
            refreshBottomBar()
        }
    }
    
    private var cameraFlashStatus: AVCaptureFlashMode = .auto {
        didSet {
            
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        photoCaptureView.cropDescription = cropDescription
        photoCaptureView.shouldSaveToAlbum = photoShouldSaveToAlbum
        photoCaptureView.cropFrame = cropFrame
        photoCaptureView.didFinishTakePhoto = { [weak self] image in
            guard let `self` = self else { return }
            self.image = image
            self.isPhotoReady = true
        }

        refreshBottomBar()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        photoCaptureView.startRunning()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        photoCaptureView.stopRunning()
    }

    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func refreshBottomBar() {
        if isPhotoReady {
            takePhotoButton.isHidden = true
            leftBottomButton.isHidden = false
            leftBottomButton.setTitle("重拍", for: .normal)
            rightBottomButton.setTitle("确定", for: .normal)
            rightBottomButton.setImage(nil, for: .normal)
        } else {
            takePhotoButton.isHidden = false
            leftBottomButton.isHidden = true
            rightBottomButton.setTitle(nil, for: .normal)
            rightBottomButton.setImage(UIImage(named: "camera_btn_switchcamera.png", in: Bundle.currentResourceBundle, compatibleWith: nil), for: .normal)
        }
    }
    
    private func refreshFlashModelStatus() {
        
    }
	
    @IBAction func clickTakePhotoButton(_ sender: UIButton) {
        photoCaptureView.takePhoto()
    }
    
    @IBAction func clickLeftBottomButton(_ sender: UIButton) {
        isPhotoReady = false
    }
    
    @IBAction func clickRightBottomButton(_ sender: UIButton) {
        if isPhotoReady {
            if image != nil {
                didFinishTakePhoto?(image!)
            }
            dismiss(animated: true, completion: nil)
        } else {
            photoCaptureView.isCameraPositionFront = !photoCaptureView.isCameraPositionFront
        }
    }
    
    @IBAction func clickCancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
