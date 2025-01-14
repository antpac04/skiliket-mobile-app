//
//  HumidityGraphViewController.swift
//  Skiliket_Reto
//
//  Created by José Antonio Pacheco on 15/10/24.
//

import UIKit
import SwiftUI

class HumidityGraphViewController: UIViewController {
    var selectedSensor: String?
    var selectedCity: String?

    @IBOutlet weak var graphContainerView: UIView!

    // Arreglo para almacenar las lecturas de humedad
    var humidityData: [Humidity] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Verificar que los valores seleccionados no sean nil
        guard let sensor = selectedSensor, let city = selectedCity else {
            print("Error: selectedSensor or selectedCity is nil")
            return
        }

        title = "\(sensor) in \(city)"
        
        // Iniciar la carga de datos y actualización de la gráfica
        loadGraph(sensor: sensor, city: city)
    }

    func loadGraph(sensor: String, city: String) {
        // Crear la vista de la gráfica y asignarla al contenedor
        let graphView = UIHostingController(rootView: HumidityLineChartUIView(humidityData: humidityData))
        addChild(graphView)
        graphView.view.frame = graphContainerView.bounds
        graphContainerView.addSubview(graphView.view)
        graphView.didMove(toParent: self)
        
        // Iniciar el censo de datos
        startDataCensus(sensor: sensor, city: city, updateInterval: 5.0)
    }

    // Función para iniciar el censo de datos periódicamente
    func startDataCensus(sensor: String, city: String, updateInterval: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            self.fetchData(sensor: sensor, city: city)
        }
    }

    // Función que obtiene los datos del sensor
    func fetchData(sensor: String, city: String) {
        let urlString = "http://localhost:8765/\(city)/\(sensor)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching data: \(String(describing: error))")
                return
            }

            do {
                let humidityPT = try JSONDecoder().decode(HumidityPT.self, from: data)
                let newHumidity = Humidity(value: String(humidityPT.humidity), timeStamp: Date())
                
                // Agregar la nueva humedad a los datos y actualizar la gráfica
                DispatchQueue.main.async {
                    self.humidityData.append(newHumidity)
                    self.updateGraph()
                }
            } catch {
                print("Error decoding data: \(error)")
            }
        }.resume()
    }

    // Actualiza la vista de la gráfica con los nuevos datos
    func updateGraph() {
        // Volver a cargar la vista de la gráfica con los datos actualizados
        let graphView = UIHostingController(rootView: HumidityLineChartUIView(humidityData: humidityData))
        for subview in graphContainerView.subviews {
            subview.removeFromSuperview()
        }
        addChild(graphView)
        graphView.view.frame = graphContainerView.bounds
        graphContainerView.addSubview(graphView.view)
        graphView.didMove(toParent: self)
    }
}
