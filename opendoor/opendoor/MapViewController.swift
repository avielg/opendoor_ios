//
//  ViewController.swift
//  opendoor
//
//  Created by Aviel Gross on 2/18/21.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    var points = [CLLocationCoordinate2D]()
    var isDrawing: Bool {
        get { return !mapView.isUserInteractionEnabled }
        set { mapView.isUserInteractionEnabled = !mapView.isUserInteractionEnabled }
    }

    var locationManager = CLLocationManager()

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var buttonDraw: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let annotation = MKPointAnnotation()
        let centerCoordinate = CLLocationCoordinate2D(latitude: 39.957592, longitude:-75.214318)
        annotation.coordinate = centerCoordinate
        annotation.title = "Title"
        mapView.addAnnotation(annotation)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

extension MapViewController {
    @IBAction func actionDraw(_ sender: UIButton) {
        isDrawing = !isDrawing
        let tint = sender.tintColor
        sender.tintColor = sender.backgroundColor
        sender.backgroundColor = tint
    }
}

// MARK: Track Touches
// Taken from: https://medium.com/@williamliu_19785/drawing-on-mkmapview-daceab966177
extension MapViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing else { super.touchesBegan(touches, with: event); return }
        mapView.removeOverlays(mapView.overlays)
        if let touch = touches.first {
            let coordinate = mapView.convert(touch.location(in: mapView),toCoordinateFrom: mapView)
            points.append(coordinate)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing else { super.touchesMoved(touches, with: event); return }
        if let touch = touches.first {
            let coordinate = mapView.convert(touch.location(in: mapView),       toCoordinateFrom: mapView)
            points.append(coordinate)
            let polyline = MKPolyline(coordinates: points, count: points.count)
            mapView.addOverlay(polyline)
        }

    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing else { super.touchesEnded(touches, with: event); return }
        let polygon = MKPolygon(coordinates: &points, count: points.count)
        mapView.addOverlay(polygon)
        points = [] // Reset points
    }
}

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = .systemGray
            polylineRenderer.lineWidth = 2
            return polylineRenderer
        } else if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.fillColor = UIColor.quaternarySystemFill.withAlphaComponent(0.3)
            return polygonView
        }
        return MKPolylineRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        mapView.setCenter(userLocation.coordinate, animated: true)

        let radius = 3000 // meters
        let distance = CLLocationDistance(exactly: radius)!
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: distance,
            longitudinalMeters: distance)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }

}
