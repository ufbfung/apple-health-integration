import UIKit
import HealthKit

class ViewController: UIViewController {
    let healthKitManager = HealthKitManager()
    @IBOutlet weak var jsonTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request HealthKit authorization when the view loads
        healthKitManager.requestAuthorization { success, error in
            if success {
                print("HealthKit authorization granted.")
            } else if let error = error {
                print("Error requesting HealthKit authorization: \(error)")
            }
        }
    }

    @IBAction func fetchDataButtonTapped(_ sender: UIButton) {
        healthKitManager.fetchHealthData { samples, error in
            if let samples = samples {
                print("Health data samples fetched: \(samples)")
                
                // Export data to JSON
                let exporter = HealthDataExporter()
                if let jsonData = exporter.exportHealthDataToJSON(samples: samples) {
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    
                    // Display JSON data in text view
                    DispatchQueue.main.async {
                        self.jsonTextView.text = jsonString
                    }
                    
                    // Save the JSON file
                    exporter.saveJSONFile(data: jsonData, fileName: "HealthData.json")
                }
            } else if let error = error {
                print("Error fetching health data: \(error)")
            }
        }
    }
}

class HealthKitManager {
    let healthStore = HKHealthStore()

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let readTypes = Set([
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!
        ])
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            completion(success, error)
        }
    }

    func fetchHealthData(completion: @escaping ([HKSample]?, Error?) -> Void) {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let distanceWalkingRunningType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let flightsClimbedType = HKObjectType.quantityType(forIdentifier: .flightsClimbed)!

        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)

        let types: [HKSampleType] = [
            heartRateType,
            stepCountType,
            sleepType,
            activeEnergyBurnedType,
            distanceWalkingRunningType,
            flightsClimbedType
        ]

        var allSamples: [HKSample] = []
        let group = DispatchGroup()

        for type in types {
            group.enter()
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, samples, error in
                if let samples = samples {
                    allSamples.append(contentsOf: samples)
                } else if let error = error {
                    print("Error fetching samples for type \(type.identifier): \(error)")
                }
                group.leave()
            }
            healthStore.execute(query)
        }

        group.notify(queue: .main) {
            completion(allSamples, nil)
        }
    }
}

class HealthDataExporter {
    func exportHealthDataToJSON(samples: [HKSample]) -> Data? {
        var healthDataArray = [[String: Any]]()
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        for sample in samples {
            if let quantitySample = sample as? HKQuantitySample {
                let type = quantitySample.quantityType.identifier
                let startDate = dateFormatter.string(from: quantitySample.startDate)
                let endDate = dateFormatter.string(from: quantitySample.endDate)
                let uuid = quantitySample.uuid.uuidString
                
                var value: Double = 0.0
                var unit: String = ""
                
                switch type {
                case HKQuantityTypeIdentifier.heartRate.rawValue:
                    value = quantitySample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    unit = "count/min"
                case HKQuantityTypeIdentifier.stepCount.rawValue:
                    value = quantitySample.quantity.doubleValue(for: HKUnit.count())
                    unit = "count"
                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    value = quantitySample.quantity.doubleValue(for: HKUnit.kilocalorie())
                    unit = "kcal"
                case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                    value = quantitySample.quantity.doubleValue(for: HKUnit.meter())
                    unit = "meter"
                case HKQuantityTypeIdentifier.flightsClimbed.rawValue:
                    value = quantitySample.quantity.doubleValue(for: HKUnit.count())
                    unit = "count"
                default:
                    continue // Skip unknown types
                }
                
                // Extract device information
                var deviceInfo: [String: Any] = [:]
                if let device = quantitySample.device {
                    deviceInfo = [
                        "name": device.name ?? "Unknown",
                        "manufacturer": device.manufacturer ?? "Unknown",
                        "model": device.model ?? "Unknown",
                        "hardwareVersion": device.hardwareVersion ?? "Unknown",
                        "firmwareVersion": device.firmwareVersion ?? "Unknown",
                        "softwareVersion": device.softwareVersion ?? "Unknown",
                        "localIdentifier": device.localIdentifier ?? "Unknown",
                        "UDIDeviceIdentifier": device.udiDeviceIdentifier ?? "Unknown"
                    ]
                }
                
                // Add more detailed information
                var metadata = quantitySample.metadata ?? [:]
                if let externalUUID = metadata[HKMetadataKeyExternalUUID] as? String {
                    metadata["externalUUID"] = externalUUID
                }
                
                let source = quantitySample.sourceRevision.source.name
                
                let sampleDict: [String: Any] = [
                    "uuid": uuid,
                    "type": type,
                    "startDate": startDate,
                    "endDate": endDate,
                    "value": value,
                    "unit": unit,
                    "metadata": metadata,
                    "source": source,
                    "device": deviceInfo
                ]
                
                healthDataArray.append(sampleDict)
            } else if let categorySample = sample as? HKCategorySample {
                let type = categorySample.categoryType.identifier
                let startDate = dateFormatter.string(from: categorySample.startDate)
                let endDate = dateFormatter.string(from: categorySample.endDate)
                let uuid = categorySample.uuid.uuidString
                
                // Extract device information
                var deviceInfo: [String: Any] = [:]
                if let device = categorySample.device {
                    deviceInfo = [
                        "name": device.name ?? "Unknown",
                        "manufacturer": device.manufacturer ?? "Unknown",
                        "model": device.model ?? "Unknown",
                        "hardwareVersion": device.hardwareVersion ?? "Unknown",
                        "firmwareVersion": device.firmwareVersion ?? "Unknown",
                        "softwareVersion": device.softwareVersion ?? "Unknown",
                        "localIdentifier": device.localIdentifier ?? "Unknown",
                        "UDIDeviceIdentifier": device.udiDeviceIdentifier ?? "Unknown"
                    ]
                }
                
                // Add more detailed information
                var metadata = categorySample.metadata ?? [:]
                if let externalUUID = metadata[HKMetadataKeyExternalUUID] as? String {
                    metadata["externalUUID"] = externalUUID
                }
                
                let source = categorySample.sourceRevision.source.name
                
                let sampleDict: [String: Any] = [
                    "uuid": uuid,
                    "type": type,
                    "startDate": startDate,
                    "endDate": endDate,
                    "value": categorySample.value,
                    "metadata": metadata,
                    "source": source,
                    "device": deviceInfo
                ]
                
                healthDataArray.append(sampleDict)
            }
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: healthDataArray, options: .prettyPrinted)
            return jsonData
        } catch {
            print("Error serializing HealthKit data to JSON: \(error)")
            return nil
        }
    }
    
    func saveJSONFile(data: Data, fileName: String) {
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: filePath, options: .atomic)
            print("JSON file saved at: \(filePath)")
        } catch {
            print("Failed to save JSON file: \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
