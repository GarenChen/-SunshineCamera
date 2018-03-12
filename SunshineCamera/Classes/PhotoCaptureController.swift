//
//  PhotoCaptureController.swift
//  SunshineCamera
//
//  Created by Garen on 2017/9/28.
//
//

import UIKit
import AVFoundation
import Photos

public class PhotoCaptureController: UIViewController {
    
    var didFinishTakePhoto: ((UIImage) -> Void)?
	
    var photoShouldSaveToAlbum: Bool = true
	
	/// 是否显示裁剪框
	var canCropImage: Bool = true
	
	/// 裁剪框区域高宽比, 仅当 canCropImage 为 true 时有效， 默认为1／1.
	/// 优先级低于 cropFrame
	var cropHWRatio: CGFloat = 1 {
		didSet {
			let screenSize = UIScreen.main.bounds.size
			cropFrame = CGRect(x: 0, y: (screenSize.height - 64 - screenSize.width * cropHWRatio) / 2, width: screenSize.width, height: screenSize.width * cropHWRatio)
		}
	}
	
	/// 裁剪框区域frame, 仅当 canCropImage 为 true 时有效.
	/// 设置为非零frame后优先级高于 cropHWRatio
	var cropFrame: CGRect = .zero
	
	/// 裁剪框下方的描述文字
	var cropDescription: String?
    
    @IBOutlet weak private var photoCaptureView: PhotoCaptureView!
    @IBOutlet weak private var rightBottomButton: UIButton!
    @IBOutlet weak private var leftBottomButton: UIButton!
    @IBOutlet weak private var takePhotoButton: UIButton!
    
	@IBOutlet weak var previewImageView: UIImageView!
	
	
    /// 初始化方法
    ///
    /// - Parameters:
    ///   - photoShouldSaveToAlbum: 是否将选择的图片保存到相册
    ///   - canCropImage: 是否显示裁剪框
    ///   - cropHWRatio: 裁剪框高宽比, 仅当 canCropImage 为 true 时有效， 默认为1／1. 优先级低于 cropFrame
    ///   - cropFrame: 裁剪框区域frame, 仅当 canCropImage 为 true 时有效.设置为非零frame后优先级高于 cropHWRatio
    ///   - cropDescription: 裁剪框下方的描述文字
    ///   - complitionHandler: 成功后回调
    public static func initiate(photoShouldSaveToAlbum: Bool = true,
                                canCropImage: Bool = true,
                                cropHWRatio: CGFloat = 1,
								cropFrame: CGRect = .zero,
								cropDescription: String? = nil,
								complitionHandler:((UIImage) -> Void)?) -> PhotoCaptureController {
        let storyboard = UIStoryboard(name: "storyboard", bundle: Bundle.currentResourceBundle)
        let controller = storyboard.instantiateViewController(withIdentifier: "PhotoCaptureController") as! PhotoCaptureController
        controller.didFinishTakePhoto = complitionHandler
        controller.photoShouldSaveToAlbum = photoShouldSaveToAlbum
		controller.canCropImage = canCropImage
		controller.cropHWRatio = cropHWRatio
		
		if cropFrame != .zero {
			controller.cropFrame = cropFrame
		}
		
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
			previewImageView.isHidden = !isPhotoReady
			previewImageView.image = image
        }
    }
	
	public override var prefersStatusBarHidden: Bool {
		return true
	}
	
    public override func viewDidLoad() {
        super.viewDidLoad()
//        photoCaptureView.cropDescription = cropDescription
        photoCaptureView.didFinishTakePhoto = { [weak self] image in
            guard let `self` = self else { return }
            self.image = image
            self.isPhotoReady = true
        }
		if canCropImage {
			photoCaptureView.setupCropView(cropFrame: cropFrame, cropDescription: cropDescription)
		}

        refreshBottomBar()
		setupFlashSwitch()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		UIApplication.shared.setStatusBarHidden(true, with: .none)
		photoCaptureView.startRunning()
	}
	
	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		UIApplication.shared.setStatusBarHidden(false, with: .none)
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
			guard image != nil else {
				dismiss(animated: true, completion: nil)
				return
			}
			
			didFinishTakePhoto?(image!)
			dismiss(animated: true, completion: nil)
			
			if self.photoShouldSaveToAlbum {
				if PHPhotoLibrary.authorizationStatus() == .authorized {
					UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
					return
				}
				PHPhotoLibrary.requestAuthorization({ [weak self] (status) in
					guard let `self` = self else { return }
					guard case .authorized = status else {
						debuglog("can not access photo library")
						return
					}
					UIImageWriteToSavedPhotosAlbum(self.image!, nil, nil, nil)
				})
			}
			
        } else {
            photoCaptureView.isCameraPositionFront = !photoCaptureView.isCameraPositionFront
        }
    }
    
    @IBAction func clickCancelButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
	
	private func setupFlashSwitch() {
		flashMode = .auto
		isFlashSelectedButtonsHidden = true
	}
	
	@IBOutlet private weak var flashModeSwitchButton: UIButton!
	@IBOutlet private weak var flashAutoButton: UIButton!
	@IBOutlet private weak var flashOpenButton: UIButton!
	@IBOutlet private weak var flashCloseButton: UIButton!

	private var flashMode: AVCaptureFlashMode = .auto {
		didSet {
			photoCaptureView.flashMode = flashMode
			var iconName = ""
			switch flashMode {
			case .auto:
				iconName = "camera_topbar_btn_flash_n.png"
				flashAutoButton.isSelected = true
				flashOpenButton.isSelected = false
				flashCloseButton.isSelected = false
			case .on:
				iconName = "camera_topbar_btn_flash_on.png"
				flashAutoButton.isSelected = false
				flashOpenButton.isSelected = true
				flashCloseButton.isSelected = false
			case .off:
				iconName = "camera_topbar_btn_flash_off.png"
				flashAutoButton.isSelected = false
				flashOpenButton.isSelected = false
				flashCloseButton.isSelected = true
			}
			flashModeSwitchButton.setImage(UIImage(named: iconName, in: Bundle.currentResourceBundle, compatibleWith: nil), for: .normal)
		}
	}
	
	private var isFlashSelectedButtonsHidden: Bool = true {
		didSet {
			flashAutoButton.isHidden = isFlashSelectedButtonsHidden
			flashOpenButton.isHidden = isFlashSelectedButtonsHidden
			flashCloseButton.isHidden = isFlashSelectedButtonsHidden
		}
	}
	
	@IBAction func clickflashSwitch(_ sender: UIButton) {
		isFlashSelectedButtonsHidden = !isFlashSelectedButtonsHidden
	}
	
	@IBAction func clickFlashAuto(_ sender: UIButton) {
		flashMode = .auto
	}
	
	@IBAction func clickFlashOpen(_ sender: UIButton) {
		flashMode = .on
	}

	@IBAction func clickFlashClose(_ sender: UIButton) {
		flashMode = .off
	}
	
}
