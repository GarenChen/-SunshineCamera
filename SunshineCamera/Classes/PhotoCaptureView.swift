//
//  PhotoCaptureView.swift
//  SunshineCamera
//
//  Created by Garen on 2017/9/28.
//
//

import UIKit
import AVFoundation

open class PhotoCaptureView: UIView {
	
	public var didFinishTakePhoto: ((UIImage) -> Void)?

    public var isCameraPositionFront: Bool = false {
        didSet {
            setCameraPosition(isFront: isCameraPositionFront)
        }
    }
    public var flashMode: AVCaptureFlashMode = .auto {
        didSet {
            guard let inputs = self.previewLayer.session.inputs else {
                return
            }
            inputs.forEach { (input) in
                guard let input = input as? AVCaptureDeviceInput, input.device.hasMediaType(AVMediaTypeVideo) else {
                    return
                }
                do {
					if input.device.isFlashAvailable && input.device.isFlashModeSupported(flashMode) {
						try input.device.lockForConfiguration()
						input.device.flashMode = flashMode
						input.device.unlockForConfiguration()
					}
					
                } catch let error {
                    debuglog("Error when setting input device flashMode: \(error)")
                    return
                }
            }
        }
    }

	private var canCropImage: Bool = false
	
	private var cropFrame: CGRect = .zero
	
	private var cropDescription: String?
	
	private lazy var session: AVCaptureSession = { [unowned self] in
		let sesssion = AVCaptureSession()
		if let input = self.input, sesssion.canAddInput(input) {
			sesssion.addInput(self.input)
		}
		if sesssion.canAddOutput(self.output) {
			sesssion.addOutput(self.output)
		}
		return sesssion
	}()
	
	private lazy var input: AVCaptureDeviceInput? = {
		guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
			return nil
		}
		do {
			if device.isFlashAvailable && device.isFlashModeSupported(self.flashMode) {
				try device.lockForConfiguration()
				device.flashMode = self.flashMode
				device.unlockForConfiguration()
			}
//			try device.lockForConfiguration()
//			device.flashMode = self.flashMode
//			device.unlockForConfiguration()
			let input = try AVCaptureDeviceInput(device: device)
			return input
		} catch let error {
			debuglog("Error when setting input device: \(error)")
			return nil
		}
	}()
	
	private lazy var output: AVCaptureStillImageOutput = {
		let output = AVCaptureStillImageOutput()
		output.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
		return output
	}()
	
	private lazy var previewLayer: AVCaptureVideoPreviewLayer = { [unowned self] in
		let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)!
		previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		previewLayer.frame = self.bounds
		return previewLayer
	}()
	
	private lazy var overlayView: UIView = { [unowned self] in
		let overLayView = UIView(frame: self.bounds)
		overLayView.alpha = 0.5
		overLayView.backgroundColor = .black
		overLayView.isUserInteractionEnabled = false
		return overLayView
	}()
	
	private lazy var cropView: UIView = { [unowned self] in
		let cropView = UIView(frame: self.cropFrame)
		cropView.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).cgColor
		cropView.layer.borderWidth = 1
		cropView.clipsToBounds = true
		return cropView
	}()
	
	private lazy var descriptionLabel: UILabel = { [unowned self] in
		let descriptionLabel = UILabel(frame: CGRect(x: 0, y: self.cropFrame.maxY + 10, width: self.bounds.width, height: 20))
		descriptionLabel.text = self.cropDescription
		descriptionLabel.font = UIFont.systemFont(ofSize: 14)
		descriptionLabel.textAlignment = .center
		descriptionLabel.textColor = .white
		return descriptionLabel
	}()
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		setupView()
	}

	public required  init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupView()
	}
	
	open override func layoutSubviews() {
		self.previewLayer.frame = self.bounds
		if self.canCropImage {
			self.overlayView.frame = self.bounds
			self.descriptionLabel.frame = CGRect(x: 0, y: self.cropFrame.maxY + 10, width: self.bounds.width, height: 20)
			overlayClipping()
		}
		super.layoutSubviews()
	}
	
	public func setupCropView(cropFrame: CGRect, cropDescription: String?) {
		self.canCropImage = true
		self.cropFrame = cropFrame
		self.cropDescription = cropDescription
		addSubview(overlayView)
		addSubview(cropView)
		addSubview(descriptionLabel)
		overlayClipping()
	}

	private func setupView() {
		layer.addSublayer(previewLayer)
	}

	private func getCaptureOrientation(from deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
		switch deviceOrientation {
		case .landscapeLeft:
			return .landscapeRight
		case .landscapeRight:
			return .landscapeLeft
		case .portraitUpsideDown:
			return .portraitUpsideDown
		default:
			return .portrait
		}
	}
	
	private func overlayClipping() {
		let maskLayer = CAShapeLayer()
		let path = CGMutablePath()
		
		/// left
		path.addRect(CGRect(x: 0, y: 0, width: cropView.frame.origin.x, height: overlayView.frame.size.height))
		
		/// right
		path.addRect(CGRect(x: cropView.frame.origin.x + cropView.frame.size.width, y: 0, width: overlayView.frame.size.width - cropView.frame.origin.x - cropView.frame.size.width, height: overlayView.frame.size.height))
		
		/// top
		path.addRect(CGRect(x: 0, y: 0, width: overlayView.frame.size.width, height: cropView.frame.origin.y))
		
		/// bottom
		path.addRect(CGRect(x: 0, y: cropView.frame.origin.y + cropView.frame.size.height, width: overlayView.frame.size.width, height: overlayView.frame.size.height - cropView.frame.origin.y + cropView.frame.size.height))
		
		maskLayer.path = path
		overlayView.layer.mask = maskLayer
	}

	public func startRunning() {
		session.startRunning()
	}
	
	public func stopRunning() {
		session.stopRunning()
	}
	
	private func setCameraPosition(isFront: Bool) {
		let cameraPosition: AVCaptureDevicePosition = isFront ? .front : .back
		let device = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)?.first(where: { (device) -> Bool in
			guard let captureDevice = device as? AVCaptureDevice, captureDevice.position == cameraPosition else {
				return false
			}
			return true
		}) as? AVCaptureDevice
		
		guard let newDevice = device else { return }
		
		self.previewLayer.session.beginConfiguration()
		
		guard let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
			return
		}
		
		self.previewLayer.session.inputs.forEach({ (input) in
			if let oldInput = input as? AVCaptureInput {
				self.previewLayer.session.removeInput(oldInput)
			}
		})
		
		self.previewLayer.session.addInput(newInput)
		self.previewLayer.session.commitConfiguration()
	}
	
	public func takePhoto() {
		
		let imageConnection = output.connection(withMediaType: AVMediaTypeVideo)
		
		let currentDevicOrientation = UIDevice.current.orientation
		
		let captrueOrientation = getCaptureOrientation(from: currentDevicOrientation)
		
		imageConnection?.videoOrientation = captrueOrientation
		
		output.captureStillImageAsynchronously(from: imageConnection) { [weak self] (imageDataSmapleBuffer, error) in
			
			guard let `self` = self else { return }
			
			guard let imageDataSmapleBuffer = imageDataSmapleBuffer else {
				debuglog("Error when captrue image : \(String(describing: error))")
				return
			}
			
			guard let jpegData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSmapleBuffer) else {
				debuglog("Error when transform imageDataSmaple to jpegData: imageDataSmapleBuffer: \(imageDataSmapleBuffer)")
				return
			}
			
			guard let fullImage = UIImage(data: jpegData) else {
				debuglog("Error when transform jpegData to UIImage: jpegData: \(jpegData)")
				return
			}

			guard let image = self.cropImage(fullImage, rect: self.cropFrame == .zero ? self.bounds : self.cropFrame) else {
                return
            }

			self.didFinishTakePhoto?(image)
		}
	}

    private func cropImage(_ image: UIImage, rect: CGRect) -> UIImage? {
		
		let baseRect = CGRect(x: 0,
		                      y: 0,
		                      width: UIScreen.main.bounds.size.width * UIScreen.main.scale,
		                      height: UIScreen.main.bounds.size.height * UIScreen.main.scale)
		
		let targetRect = CGRect(x: rect.origin.x * UIScreen.main.scale,
		                        y: rect.origin.y * UIScreen.main.scale,
		                        width: rect.size.width * UIScreen.main.scale,
		                        height: rect.size.height * UIScreen.main.scale)
		
        UIGraphicsBeginImageContext(baseRect.size)
		
        image.draw(in: baseRect)
		
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let newImage = scaledImage?.cgImage?.cropping(to: targetRect) else {
            return nil
        }
		
		let resultImage = UIImage(cgImage: newImage)
        return resultImage
    }
	
}
