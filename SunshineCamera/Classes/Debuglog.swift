import Foundation

#if DEBUG
	func debuglog(_ items: Any...) {
		print(items)
	}
#else
	func debuglog(_ items: Any...) {
	}
#endif
