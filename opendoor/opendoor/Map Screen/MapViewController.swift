//
//  ViewController.swift
//  opendoor
//
//  Created by Aviel Gross on 2/18/21.
//

import UIKit
import MapKit
import Combine

class ImageAndTitleButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setTitleColor(tintColor, for: .normal)
        layer.cornerRadius = 12
    }
}

class MapViewController: UIViewController {

    var dataSourcesAssignCancellable: AnyCancellable?
    var dataSources = DataProvider.shared.dataSources {
        didSet {
            let annotations = dataSources.map{ $0.points }.reduce([], +).map{ $0.annotation }
            allAnnotations.append(contentsOf: annotations)
        }
    }

    /// All available annotations.
    var allAnnotations = [MKAnnotation]() {
        didSet {
            // Resets the annotations shown on the map
            self.shownAnnotations = self.allAnnotations
        }
    }

    /// Currently rendered annotations. When drawing a certain area
    /// of the map, these will be a subset of `allAnnotations`.
    var shownAnnotations = [MKAnnotation]() {
        didSet {
            guard !shownAnnotations.elementsEqual(oldValue, by: {
                $0.coordinate.latitude == $1.coordinate.latitude
                    && $0.coordinate.longitude == $1.coordinate.longitude
            }) else { return }

            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(shownAnnotations)

            mapView.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: [
                .airport, .museum, .park, .school, .zoo
            ]))

            buttonFoundAddresses.isHidden = shownAnnotations.isEmpty
            buttonFoundAddresses.setTitle("\(shownAnnotations.count) Addresses", for: .normal)
        }
    }

    var points = [CLLocationCoordinate2D]()
    var isDrawing: Bool {
        get { return !mapView.isUserInteractionEnabled }
        set {
            guard isDrawing != newValue else { return }
            mapView.isUserInteractionEnabled = !newValue
            let tint = buttonDraw.tintColor
            buttonDraw.tintColor = buttonDraw.backgroundColor
            buttonDraw.backgroundColor = tint
        }
    }

    let locationManager = CLLocationManager()
    let geocoder = CLGeocoder()

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var buttonDraw: UIButton!
    @IBOutlet weak var buttonFoundAddresses: UIButton!
    @IBOutlet weak var buttonDataSources: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSourcesAssignCancellable = DataProvider.shared.$dataSources.assign(to: \.dataSources, on: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == "showAddressesSegue",
            let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? AddressesViewController
        {
            vc.addresses = shownAnnotations
        }
        isDrawing = false
    }
}

// MARK: Map Logic
extension MapViewController {
    func showMapAnnotations(inside polygon: MKPolygon) {
        guard polygon.pointCount > 1 else { return } // empty polygon or single dot

        var annotations = [MKAnnotation]()

        for annotation in allAnnotations {
            let mapPoint = MKMapPoint(annotation.coordinate)
            let polygonRenderer = MKPolygonRenderer(polygon: polygon)

            let polygonPoint = polygonRenderer.point(for: mapPoint)
            let mapCoordinateIsInPolygon = polygonRenderer.path.contains(polygonPoint)

            if mapCoordinateIsInPolygon { annotations.append(annotation) }
        }

        shownAnnotations = annotations
        mapView.setVisibleMapRect(
            polygon.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
            animated: true)
    }
}

// MARK: UI Logic
extension MapViewController {
    private func toggleDrawing() {
        isDrawing = !isDrawing
    }
}

// MARK: IBActions
extension MapViewController {
    @IBAction func unwindAction(unwindSegue: UIStoryboardSegue) {}

    @IBAction func actionDraw(_ sender: UIButton) { toggleDrawing() }
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

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let propertyAnnotation = annotation as? PropertyAnnotation else { return nil }
        if let mView = mapView.dequeueReusableAnnotationView(withIdentifier: PropertyAnnotationView.reuseIdentifier) as? PropertyAnnotationView {
            mView.annotation = propertyAnnotation
            mView.setupIcon(propertyAnnotation)
            return mView
        }
        return PropertyAnnotationView(propertyAnnotation: propertyAnnotation)
    }

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

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard
            let propertyView = view as? PropertyAnnotationView,
            let propertyAnnotation = propertyView.annotation as? PropertyAnnotation
        else {
            return
        }
        let vc = PropertyDetailViewController()
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.sourceView = view
        vc.data = propertyAnnotation.property
        self.present(vc, animated: true, completion: nil)
    }

}
