//
//  PhotoCaptureView.swift
//  Pods
//
//  Created by Garen on 2017/9/28.
//
//

import UIKit
import AVFoundation
import Photos

open class PhotoCaptureView: UIView {
	
	public var didFinishTakePhoto: ((UIImage) -> Void)?
	
	public var shouldSaveToAlbum: Bool = true
	
	public var cropFrame: CGRect = .zero
	
	public var cropDescription: String = ""
	
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
			try device.lockForConfiguration()
			device.flashMode = AVCaptureFlashMode.auto
			device.unlockForConfiguration()
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
		let cropView = UIView(frame: self.cropFrame == .zero ? self.bounds : self.cropFrame)
		cropView.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).cgColor
		cropView.layer.borderWidth = 1
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
	
	private func setupView() {
		layer.addSublayer(previewLayer)
		addSubview(overlayView)
		addSubview(cropView)
		addSubview(descriptionLabel)
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
	
	func startRunning() {
		self.session.startRunning()
	}
	
	func stopRunning() {
		self.session.stopRunning()
	}
	
	func setCameraPosition(isFront: Bool) {
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
	
	func takePhoto() {
		
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
			
			guard let image = UIImage(data: jpegData) else {
				debuglog("Error when transform jpegData to UIImage: jpegData: \(jpegData)")
				return
			}
			
			self.didFinishTakePhoto?(image)
			
			if self.shouldSaveToAlbum {
				if PHPhotoLibrary.authorizationStatus() == .authorized {
					UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
					return
				}
				PHPhotoLibrary.requestAuthorization({ (status) in
					guard case .authorized = status else {
						debuglog("can not access photo library")
						return
					}
					UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
				})
			}
		}
	}
	
}