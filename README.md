# Overview
This repository is used for extracting health data from apple health via HealthKit and analyzed in Python. The goal will be to develop an integration of Apple Health data into FHIR to enable better integration with other health applications.

# Apple Health integration via HealthKit
I developed a lightweight iOS app using Swift called HealthDataCollector to extract health data from my Apple iPhone via HealthKit. Currently, it's only limited to certain data types and may not contain all the raw data as I'm still learning the schemas for how apple stores their device data, which isn't always from Apple products. All the code can be found in [HealthDataCollector](https://github.com/ufbfung/apple-health-integration/tree/main/HealthDataCollector) and the project files can be found in [HealthDataCollector.xcodeproj](https://github.com/ufbfung/apple-health-integration/tree/main/HealthDataCollector.xcodeproj).

# Data processing using Python
Apple's data is exported as JSON and I plan on using Python to do perform ETL on the raw JSON file that will include 1) extraction into pydantic models, 2) enrichment with external data sources, including healthcare data standards, 3) transformation into fast healthcare interoperability resources (FHIR) to enable more seamless transfer to other applications, and 4) import into a Google FHIR Store via the Healthcare API to integrate with a larger, integrated health record. 

# Snippet of health data extracted from Apple
There's a lot of data that apple aggregates and I'm planning to slowly integrate each one as I find interest in them. Below represents the data types that I've currently extracted along with some other interesting insights during data profiling in Python.

## Summary stats
|Data type|Count|Min|Max|Average|Median|Period|
|--|--|--|--|--|--|--|
|Step count|544|1.0|1007.0|207.8|72.0|May 26, 2024 - Jun 2, 2024|
|Active energy burned|5032|0.0|86.4|0.86|0.15|May 26, 2024 - Jun 2, 2024|
|Heart rate|4551|45|138|90.8|97|May 26, 2024 - Jun 2, 2024|

## Devices
|Name|Manufacturer|Model|Hardware Version|Firmware Version|Software Version|
|--|--|--|--|--|--|
|Apple Watch|Apple Inc.|Watch|Watch6.1|Unknown|10.5|
|iPhone|Apple Inc.|iPhone|iPhone16.1|Unknown|17.5.1|
|iPhone|Apple Inc.|iPhone|iPhone16.1|Unknown|17.4.1|
|Apple Watch via Apple Health|Withings|Withings Tracker|Unknown|Unknown|Unknown|
|Body Smart|Withings|Withings Scale|0|1071|Unknown|
