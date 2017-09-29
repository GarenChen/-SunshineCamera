//  Created by Garen on 2017/9/7.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class BundleClass: NSObject {
}

extension Bundle {
	static var currentResourceBundle: Bundle? {
		let path =  Bundle(for: BundleClass.self).path(forResource: "SunshineCamera", ofType: "bundle") ?? ""
		return Bundle(path: path)
	}
}
