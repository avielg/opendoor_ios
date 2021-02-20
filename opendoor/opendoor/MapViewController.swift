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

        let places: [(String, String)] = [
            ("319 MARKET STREET Philadelphia, PA 19106 nan", "Cegrani Llc"),
            ("3800-3900 CITY AVE., APT. W421 AKA 3950 CITY AVE. PHILADELPHIA, PA 19131", "Robert Saul"),
            ("1340 S NEWKIRK ST Philadelphia, PA 19146 nan", "Melinda Lincoln"),
            ("553 E CHELTENHAM AVENUE PHILADELPHIA, PA 19120 nan", "Morkeh Navo, Solomon Masson Navo"),
            ("2607 WELSH RD BUILDING L # L308 PHILADELPHIA, PA 19114 nan", "Raihaanah Yazeed"),
            ("5714 Filbert Street Philadelphia, PA 19139 nan", "Candice Walker, Mario Gallashaw"),
            ("2801 N FAIRHILL ST 1ST FL PHILADELPHIA, PA 19133", "Pedro J Vega"),
            ("5150 W Girard Ave Philadelphia, PA 19131 nan", "Christina Crain, Stephen Brad Paxton"),
            ("3750 WOODHAVEN RD #1201 ENT @ 3850 WOODHAVEN RD # 1502 PHILADELPHIA, PA 19154 nan", "Robert Pollard"),
            ("9951 Academy Road Apt. G-1 Philadelphia, PA 19114", "Nyasha Tumbull, Jerald Bedell"),
            ("155 E. Godfrey Avenue # G-306 Philadelphia, PA 19120 nan", "Johnathon Moore Jr"),
            ("2607 WELSH RD BLDG M # M202 PHILADELPHIA, PA 19114 nan", "Gardy Mercedat"),
            ("3000 Woodhaven Road a/k/a 131 Thornwood Place Philadelphia, PA 19154", "Jessica Caine"),
            ("6210 E Roosevelt Blvd AKA 6219 Everett St ENT @ 6219 EVERETT ST # A Phila, PA 19149", "Elliot Pearlman"),
            ("1120 N. 66TH STREET AKA 1120-1121 NORTH 66TH STREET, APT 13-C PHILADELPHIA, PA 19151", "Kerrykay Thompson"),
            ("3817 ELSINORE ST PHILADELPHIA, PA 19124 nan", "Gladys Moreno"),
            ("3900 GATEWAY DR #1 ENT @ 3920 Gateway Dr # C1 PHILADELPHIA, PA 19145 nan", "Jonathan Massaro, Nohely Massaro"),
            ("110 Pleasant Hill Rd Cheltenham, PA 19012 nan", "Margarita Agosto"),
            ("2465 N 50TH ST. # E310 Philadelphia, PA 19131 nan", "Bader Bin Tuwalah, Abdulmageed A Alzharani"),
            ("6451 OXFORD AVE # A203 PHILA, PA 19111 nan", "Jamela Jackson"),
            ("861 N UBER STREET FRANCISVILLE PHILADELPHIA, PA 19130", "Sherriel Lewis"),
            ("5130 N MARVINE ST 3RD FL PHILADELPHIA, PA 19141", "Tabera Williams"),
            ("7801 E ROOSEVELT BLVD # 55 PHILADELPHIA, PA 19152 nan", "David Fletcher"),
            ("4046 OGDEN ST AKA 4052 OGDEN ST ENT @ 4052 OGDEN ST # A PHILA, PA 19104", "Sade Kenner"),
            ("2100 E Ann Street 2nd Floor Philadelphia, PA 19134", "Adam Abdullah"),
            ("6515 EVERETT STREET AKA 6512 LARGE STREET ENT. @6512 LARGE STREET # 2 PHILADELPHIA, PA 19149", "Jenny Falwn Bernie, Lourdvens Pierre"),
            ("2328 N 30TH STREET GORDON STREET APARTMENTS PHILADELPHIA, PA 19132", "Diamond Murray"),
            ("7011 NORTH 15TH STREET # 2C4 PHILADELPHIA, PA 19126 nan", "Toinettie James"),
            ("5220 WAYNE AVE. AKA 5220-5224 WAYNE AVE ENT. @ 5220-5224 WAYNE AVE # 306S PHILADELPHIA, PA 19144", "Gamal A Williams"),
            ("4239 Sansom Street #1A Philadelphia, PA 19104", "Aaliyah Haley"),
            ("2304 N. GRATZ STREET PHILADELPHIA, PA 19132 nan", "Brittani Outterbridge"),
            ("5604 HARLEY DR, #01B BARTRAM VILLAGE PHILADELPHIA, PA 19143", "Anthony Cream"),
            ("1101 N 63RD ST # G1 PHILA, PA 19151 nan", "Johnny Murphy"),
            ("7901 E ROOSEVELT BLVD # 38 PHILADELPHIA, PA 19152 nan", "Marilyn Santos"),
            ("2443 North 11th Street #1201 Fairhill Apartments Philadelphia, PA 19133", "Caprice Williams"),
            ("5005 CHESTER AVENUE, B PHILADELPHIA, PA 19143 nan", "Jeanine Turner, Jasmine Turner"),
            ("3672 FRANKFORD AVE PHILADELPHIA, PA 19134 nan", "Bryheem Smith"),
            ("2020 E. Tioga Street 1st Floor Philadelphia, PA 19134", "Cierra Simone Frazier, Isaiah Leslie Thomas"),
            ("6132 PINE STREET PHILADELPHIA, PA 19143 nan", "Latonya Hill"),
            ("1824 HARRISON STREET # 3 PHILADELPHIA, PA 19124 nan", "Edward Kempton"),
            ("2123 CARVER STREET PHILADELPHIA, PA 19124 nan", "Brenda Torres"),
            ("6025 E. Roosevelt Blvd aka 6063 Roosevelt Blvd ENT @ 6063 E. ROOSEVELT BOULEVARD # 22 Philadelphia, PA 19149", "Jasmine Curcio, Donte M Jackson"),
            ("5016 PINE ST # 401 PHILADELPHIA, PA 19143 nan", "Leon Wells"),
            ("2020 S BOUVIER ST PHILA, PA 19145 nan", "Grace M Meirino"),
            ("3501 Woodhaven Road Unit 134 Philadelphia, PA 19154", "Amani Burke"),
            ("One Franklintown Blvd. #1910 Philadelphia, PA 19103", "Alexis Jenkins"),
            ("1621 S FRAZIER STREET 2ND FLOOR PHILADELPHIA, PA 19143", "Dimira Jones, Emmett Harris Iii"),
            ("7216A SAYBROOK AVENUE PASCHALL VILLAGE I PHILADELPHIA, PA 19142", "Blair Greene"),
            ("701 SUMMIT AVE # D117 PHILADELPHIA, PA 19128 nan", "Jessicanne Durkin"),
            ("12019 Legion Street Philadelphia, PA 19154 nan", "Katheen D Dolbow, Samuel Louis Ladd"),
            ("1419 N ALDEN ST PHILA, PA 19131 nan", "Emani H Sawyer"),
            ("4231 PARRISH ST PHILADELPHIA, PA 19104 nan", "Charlene Jenkins"),
            ("3111 Grays Ferry Avenue Philadelphia, PA 19146 nan", "Edward A. Hildebrandt Iii, University Collission Center Inc., Uc Tech Inc., Tina Hildebrandt"),
            ("3001 MOORE STREET #203 GREATER GRAYS FERRY ESTATES I PHILADELPHIA, PA 19145", "Tawanda Lee"),
            ("4129 ORCHARD STREET PHILADELPHIA, PA 19124 nan", "Aaliyah Blatch, Christopher Mcnair-Tull"),
            ("2003 W. YORK STREET PHILADELPHIA, PA 19132 nan", "Shanetta R. Ledbetter"),
            ("4600 SPRUCE ST # 2B PHILADELPHIA, PA 19139 nan", "Stephen Waters"),
            ("613 N 39TH ST PHILA, PA 19104 nan", "Aasiya Johnson"),
            ("2059 PICKWICK STREET PHILADELPHIA, PA 19134 nan", "Neisha Myers"),
            ("2077 E. LIPPINCOTT STREET PHILADELPHIA, PA 19134 nan", "Michael Shank"),
            ("6647 CLARIDGE STREET PHILADELPHIA, PA 19111 nan", "Teresa M Colisto"),
            ("4910 A COMLY ST.AKA 5929 KEYSTONE ST. PHILA., PA 19135 nan", "Jennifer Diane Meleski"),
            ("7901 Henry Ave. Apt. A 504 Philadelphia, PA 19128", "Shahdera Petty"),
            ("4653 N Penn St., 1st Floor Phila, PA 19124 nan", "Beth Parks"),
            ("5600 OGONTZ AVE # D51 PHILA, PA 19141 nan", "James Richo, James Richo"),
            ("5150 D STREET 1ST FLOOR UNIT #3 PHILADELPHIA, PA 19120", "Montez Devine-James"),
            ("147 N. Wanamaker Street Philadelphia, PA 19139 nan", "Florine Smith, Florine Smith"),
            ("2007 N. GRATZ STREET PHILADELPHIA, PA 19121 nan", "Zahira K. Poree"),
            ("3098 1/2 Ruth St. 1st Floor Philadelphia, PA 19134", "Eddie Dyson, Jesse Winouski"),
            ("3800-3900 CITY AVE., APT. W223 AKA 3950 CITY AVE PHILADELPHIA, PA 19131", "Donte Howard"),
            ("6770 BLAKEMORE STREET aka 6748-6788 BLAKEMORE AVE.. UNIT 6770 - A1 PHILADELPHIA, PA 19119", "Keisha Hardrick"),
            ("2629 Mulfeld Street Philadelphia, PA 19142 nan", "Eunique Moore"),
            ("4725 Pine Street Philadelphia, PA 19143 nan", "Stand Up Enterprises, Inc."),
            ("6819 Jackson Street-1st Floor Philadelphia, PA 19135 nan", "Stacey Anne Anderson, Victoria Anderson"),
            ("1717 S HOLLYWOOD STREET GREATER GRAYS FERRY ESTATES I PHILADELPHIA, PA 19145", "Kameka Mack"),
            ("4938 N Broad Street Philadelphia, pa 19141 nan", "Kashmir Young, Taijuan Falana"),
            ("7219 Marsden Street Unit 1 Philadelphia, PA 19135", "Mahmoud Elamin Gasme Gumaa"),
            ("155 E. Godfrey Avenue # K-205 Philadelphia, PA 19120 nan", "Christopher Horne, Tiarah Estep"),
            ("5215 SCHUYLER STREET # A203 PHILADELPHIA, PA 19144 nan", "Fama Lo, Olatundji Diogo"),
            ("5030 Tulip Street Phila, PA 19124 nan", "Tawana Hughes, Anthony Brown"),
            ("3446 KEIM ST PHILA, PA 19134 nan", "Sherri Wilson Crawford, Michael Henderson"),
            ("3601 Conshohocken Ave Unit 219 Philadelphia, PA 19131", "Ebony Avery"),
            ("2935 N 26th Street Front Room Philadelphia, PA 19132", "Dannett Bluford"),
            ("6616 TORRESDALE AVE. # 2ND FLOOR PHILADELPHIA, PA 19135 nan", "Augustine Quinones"),
            ("5738 North Marshall Street Philadelphia, PA 19120 nan", "Theresa Williams"),
            ("6047 Delancey Street 1st floor Phila, PA 19143", "Karen E Avent"),
            ("3024 D STREET PHILADELPHIA, PA 19134 nan", "September Wingfield, Charles Woodson"),
            ("1638 W JUNIATA ST PHILADELPHIA, PA 19140 nan", "Shameeka Jenkins"),
            ("6511 N Camac Street Apt. 5 Philadelphia, PA 19126", "Christopher Watts, Shereena White"),
            ("1529 Dickinson Street 1st Floor Front Philadelphia, PA 19146", "Danilos Calvac Chavez"),
            ("1155 SOUTH 15TH STREET UNIT # 107 PHILADELPHIA, PA 19146", "Caitlyn Molinaro"),
            ("3123 Diamond St AKA 3123 W Diamond St Ent @ 3123 W Diamond St #A Phila, PA 19121", "Albert White"),
            ("1100 W Godfrey Ave Bldg A ent @ 1100 W. Godfrey Ave # G215 PHILADELPHIA, PA 19141 nan", "Daniel Green"),
            ("5729 N Fairhill Street 1st Floor Philadelphia, PA 19120", "Iris Roland"),
            ("4920 CITY AVENUE # A209 Philadelphia, PA 19131 nan", "Andrea D Williams"),
            ("5223 Master Street 2nd Floor Front Philadelphia, PA 19131", "Erica Jacobs"),
            ("155 E. Godfrey Avenue # C-304 Philadelphia, PA 19120 nan", "John Jones"),
            ("355 EAST SHARPNACK STREET PHILADELPHIA, PA 19119 nan", "Joseph Randolph King"),
            ("121 S 60TH ST # 1ST FL PHILA, PA 19139 nan", "Moctar Ibrahim Dba Zoras Closet"),
        ]

        print("START: \(Date())")
        draw(locations: places)
    }

    private func draw(locations: [(String, String)]) {
        guard let place = locations.first else {
            print("END: \(Date())")
            return
        } // stop recursion

        geocoder.geocodeAddressString(place.0) { [weak self] placemarks, error in
            guard let self = self else { return }
            defer { self.draw(locations: Array(locations.dropFirst())) }
            guard let placemark = placemarks?.first,
                  let l = placemark.location
            else {
                print("No Location!")
                return
            }
            let annotation = MKPointAnnotation()
            annotation.coordinate = l.coordinate
            annotation.title = place.1
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

        let radius = 10000 // meters
        let distance = CLLocationDistance(exactly: radius)!
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: distance,
            longitudinalMeters: distance)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }

}
