//
//  ViewController.swift
//  mapWitMapBox
//
//  Created by Howard Chang on 2/22/20.
//  Copyright © 2020 Howard Chang. All rights reserved.
//

import UIKit
import Mapbox
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation

class ViewController: UIViewController {

    var directionsRoute: Route?
    var mapView: NavigationMapView!
    var pursuitCoordinates = CLLocationCoordinate2D(latitude: 40.74296, longitude: -73.94411)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "mapbox://styles/howc/ck5gy6ex70k441iw1gqtnehf5")
        mapView = NavigationMapView(frame: view.bounds, styleURL: url)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        //mapView.setCenter(CLLocationCoordinate2D(latitude: 59.31, longitude: 18.06), zoomLevel: 9, animated: false)
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
        addButton()
    }

    func addButton() {
        let button = UIButton(frame: CGRect(x: (view.frame.width/2) - 100, y: view.frame.height - 75, width: 200, height: 50))
        button.backgroundColor = .white
        button.setTitle("Navigate", for: .normal)
        button.setTitleColor(UIColor(red: 59/255, green: 178/255, blue: 208/255, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        button.layer.cornerRadius = 25
        button.layer.shadowOffset = CGSize(width: 0, height: 10)
        button.layer.shadowColor = UIColor.gray.cgColor
        button.layer.shadowRadius = 5
        button.layer.shadowOpacity = 0.4
        button.addTarget(self, action: #selector(navi(_:)), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func navi(_ sender: UIButton) {
        mapView.setUserTrackingMode(.none, animated: true, completionHandler: nil)
        let annotation = MGLPointAnnotation()
        annotation.coordinate = pursuitCoordinates
        annotation.title = "Start Navigation"
        mapView.addAnnotation(annotation)
        calculateRoute(from: mapView.userLocation!.coordinate, to: pursuitCoordinates) { (route, error) in
            if error != nil {
                print("error getting route")
            }
        }
    }
    
    func calculateRoute(from originCoord: CLLocationCoordinate2D, to destinationCoord: CLLocationCoordinate2D, completion: @escaping (Route?,Error?) -> Void) {
        let origin = Waypoint(coordinate: originCoord, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destinationCoord, coordinateAccuracy: -1, name: "Finish")
        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
        _ = Directions.shared.calculate(options, completionHandler: { [unowned self] (waypoints, routes, error) in
            guard let directionRoute = routes?.first else { return }
            self.directionsRoute = directionRoute
            self.drawRoute(route: directionRoute)
            let coordinateBounds = MGLCoordinateBounds(sw: destinationCoord, ne: originCoord)
            let insets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            let routeCam = self.mapView.cameraThatFitsCoordinateBounds(coordinateBounds, edgePadding: insets)
            self.mapView.setCamera(routeCam, animated: true)
        })
    }
    
    func drawRoute(route: Route) {
        guard route.coordinateCount > 0 else { return }
        var routeCoordinates = route.coordinates!
        let polyLine = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyLine
        } else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyLine], options: nil)
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            lineStyle.lineColor = NSExpression(forConstantValue: UIColor.green)
            lineStyle.lineWidth = NSExpression(forConstantValue: 4.0)
            lineStyle.lineCap = NSExpression(forConstantValue: "round")
            mapView.style?.addSource(source)
            mapView.style?.addLayer(lineStyle)
        }
    }
    

}

extension ViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        guard let setDirection = directionsRoute else { return }
        let navVC = NavigationViewController(for: setDirection)
        present(navVC, animated: true)
    }
}
