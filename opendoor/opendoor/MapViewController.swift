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

    let locationManager = CLLocationManager()
    let geocoder = CLGeocoder()

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var buttonDraw: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let placesData = Parser.parseCSV(named: "geocode_data") ?? []
        print("GEO: \(placesData.count) places")

        for place in placesData {
            guard
                place.count > 3,
                let lat = Double(place[2]),
                let lon = Double(place[3])
            else {
                continue
            }
            let name = place[1]

            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            annotation.title = name
            self.mapView.addAnnotation(annotation)
        }
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

// MARK: Map Logic
extension MapViewController {
    func showMapAnnotations(inside polygon: MKPolygon) {
        guard polygon.pointCount > 1 else { return } // empty polygon or single dot
        for annotation in mapView.annotations {
            let mapPoint = MKMapPoint(annotation.coordinate)
            let polygonRenderer = MKPolygonRenderer(polygon: polygon)

            let polygonPoint = polygonRenderer.point(for: mapPoint)
            let mapCoordinateIsInPolygon = polygonRenderer.path.contains(polygonPoint)

            mapView.view(for: annotation)?.isHidden = !mapCoordinateIsInPolygon
        }
    }
}

// MARK: IBActions
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
        showMapAnnotations(inside: polygon)
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

        let radius = 10000 // meters
        let distance = CLLocationDistance(exactly: radius)!
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: distance,
            longitudinalMeters: distance)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }

}
