//
//  PropertyAnnotationView.swift
//  opendoor
//
//  Created by Aviel Gross on 2/26/21.
//

import UIKit
import MapKit

/**
 Represents a view with:
    - An icon
    - White circular background view for the icon.
*/
class IconPinView: UIView {

    fileprivate var iconImageView: UIImageView?

    /**
     Should always be called after 'init'!

     - parameter alpha: the expected alpha for the view
     */
    func setup(_ alpha: CGFloat = 1.0) {
        // white back view
        let mainPinVisibleDiameter = CGFloat(20)
        let size = CGSize(width: mainPinVisibleDiameter, height: mainPinVisibleDiameter)
        let v = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        setBackColor(with: alpha, forView: v)
        v.layer.cornerRadius = v.frame.width / 2 //make it circle
        v.layer.masksToBounds = true
        v.center.x = center.x //position it
        v.center.y = frame.width / 2
        v.tag = "backview_tag".hash

        // add the views to self (the container view)
        addSubview(v)
    }

    func updateAlpha(_ alpha: CGFloat = 1.0) {
        guard let v = viewWithTag("backview_tag".hash)
            else {return}
        setBackColor(with: alpha, forView: v)
    }

    fileprivate func setBackColor(with alpha: CGFloat = 1.0, forView v: UIView) {
        v.backgroundColor = UIColor(white: 1, alpha: alpha * 1.5)
    }

    /**
     Add an icon to the pin. Does not
     override any existing icon. Will
     change any existing icon.

     - parameter icon: the icon to add
     */
    func insertIcon(_ icon: UIImage) {

        if let iv = iconImageView {
            iv.image = icon
        } else {
            iconImageView = UIImageView(image: icon)
            _ = iconImageView.map(addSubview)
        }

        // icon
        iconImageView?.center.x = center.x
        iconImageView?.center.y = frame.width / 2

    }


    /// Will be the icon and the pin tint color
    var color: UIColor = UIApplication.shared.delegate?.window??.tintColor ?? UIColor.black {
        didSet {
            // whenever the color changes > change
            //  the tint for any subview
            for i in subviews.compactMap({ $0 as? UIImageView }) {
                i.tintColor = color
            }
        }
    }

}

//MARK: - Protocols

@objc protocol MarkerAnnotation: class, MKAnnotation {}

protocol VisualAnnotation: MarkerAnnotation {
    var iconName: String? { get }
    var color: UIColor { get }
}

extension MKAnnotationView {
    /// Setup Icon
    func setupIcon(_ annotation: VisualAnnotation) {

        // get the color
        let color = annotation.color

        // suck color vals
        var alpha: CGFloat = 0
        var white: CGFloat = 0
        color.getWhite(&white, alpha: &alpha) //get alpha


        // make the pin or get an existing one
        // (when dequeing reausable marker from map)
        let iconPin: IconPinView
        let newPin: Bool // if it's new, we add it as subview later
        if let pin = subviews.compactMap({$0 as? IconPinView}).first {
            iconPin = pin
            iconPin.updateAlpha(alpha) // update for marker color
            newPin = false
        } else {
            iconPin = IconPinView(frame: frame)
            iconPin.setup(alpha) // setup with the marker color
            newPin = true
        }

        // add the icon
        if let
            name = annotation.iconName,
            let img = UIImage(systemName: name) {
                iconPin.insertIcon(img)
        }

        iconPin.color = color
        frame = iconPin.frame

        if newPin { addSubview(iconPin) }
    }
}

/**
 A view for a single marker, representing
 a single accident.
*/
class PropertyAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "PropertyAnnotationViewReuseIdentifier"
    convenience init(propertyAnnotation: PropertyAnnotation, reuseIdentifier: String! = reuseIdentifier) {
        self.init(annotation: propertyAnnotation, reuseIdentifier: reuseIdentifier)

        isEnabled = true
        rightCalloutAccessoryView = UIButton.init(type: .detailDisclosure)
        canShowCallout = true
        isUserInteractionEnabled = true
        setupIcon(propertyAnnotation)
    }
}
