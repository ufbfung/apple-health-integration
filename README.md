# apple-health-integration
This repository is used for extracting health data from apple health via HealthKit and analyzed in Python. The goal will be to develop an integration of Apple Health data into FHIR to enable better integration with other health applications.

# Apple Health integration via HealthKit
I developed a lightweight iOS app using Swift called HealthDataCollector to extract health data from my Apple iPhone via HealthKit. Currently, it's only limited to certain data types and may not contain all the raw data as I'm still learning the schemas for how apple stores their device data, which isn't always from Apple products. All the code can be found in [HealthDataCollector](https://github.com/ufbfung/apple-health-integration/tree/main/HealthDataCollector) and the project files can be found in [HealthDataCollector.xcodeproj](https://github.com/ufbfung/apple-health-integration/tree/main/HealthDataCollector.xcodeproj).

# Data processing using Python
Apple's data is exported as JSON and I plan on using Python to do perform ETL on the raw JSON file that will include 1) extraction into pydantic models, 2) enrichment with external data sources, including healthcare data standards, 3) transformation into fast healthcare interoperability resources (FHIR) to enable more seamless transfer to other applications, and 4) import into a Google FHIR Store via the Healthcare API to integrate with a larger, integrated health record. 
