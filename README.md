# ConnectedCarDemo
Recording: [Connected Car Recording - Jonathan Cooper-Ellis](https://www.youtube.com/watch?v=v0p55fbaDyE)

Components Involved:
  - Arcadia Data
  - StreamSets
  - Kudu
  - Spark Streaming
  - Kafka
  - Solr
  - Impala

## Overview
This IoT-themed demo shows ingest, processing, and analysis of simulated connected car data. Raw sensor data is used to construct a driver behavior profile for each vehicle which is used to make custom maintenance recommendations, and track other behaviors and events. This is done through the following steps:
  1. Data is generated in a Kafka Producer and written to a Kafka topic.
  2. StreamSets reads data from that Kafka topic.
  3. StreamSets writes all events to a different Kafka topic, and writes certain events (collisions, hazards, and illegal lane departures) to a Solr collection.
  4. Spark Streaming reads from the Kafka topic written to by StreamSets, reads existing profile data from Kudu, merges the raw readings into any existing profile data, and updates the Kudu table storing driver profiles.
  5. Data is explored through Hue/Search (or a BI tool of your choosing).

This demo was created with several use-cases in mind (though it may be relevant to other situations):
  - Auto manufacturers who want to understand how their vehicles are actually being driven, and/or leverage profiles of each vehicle to best support their customers
  - Insurance companies who want to understand driver behaviors, and/or adjust rates based on driving habits
  - Public safety/DoT-type organizations who want to analyze traffic patterns, and/or alerting for road hazards, collisions, etc. in NRT.
  - Uber-type use cases (http://venturebeat.com/2016/01/26/ubers-using-gyrometer-and-accelerometer-data-from-smartphones-to-verify-user-feedback/), where the car itself does not need to be connected because accelerometer data from the driver's phone can be used.


## Demo Steps
1. Set up a Cloudera cluster which includes all required services (listed above under "Components Involved") and their dependencies, and copy demo code/files to a cluster gateway node.
2. cd into $CONNECTED_CAR_DEMO/demo/streaming and build the jar by running `$ mvn clean package`
3. Open 2 terminal windows and ssh to a cluster gateway node.
4. In your web browser, open the StreamSets UI by navigating to `STREAMSETS_HOST:18630` and logging in with admin/admin credentials. Then pull up the "Connected Car Demo" pipeline and make sure that it is running.
5. To start the Spark Streaming job, run the following command in the first terminal: `$ spark-submit --master yarn --deploy-mode client --executor-memory 2g --num-executors 2 --class com.cloudera.demo.connected_car.ConnectedCarStreaming $CONNECTED_CAR_DEMO/demo/target/ConnectedCar.jar <KAFKA_HOST_1>:9092,<KAFKA_HOST_2>:9092,<KAFKA_HOST_3>:9092 <KUDU_MASTER_HOST> <ZOOKEEPER_HOST>:2181/solr connected_car_streaming`
6. To start the data generator, run the following command in the second terminal: `$ java -cp $CONNECTED_CAR_DEMO/demo/target/ConnectedCar.jar com.cloudera.demo.connected_car.ConnectedCarReadingGenerator <KAFKA_HOST_1>:9092,<KAFKA_HOST_2>:9092,<KAFKA_HOST_3>:9092 $CONNECTED_CAR_DEMO/demo/conf/1000_cars.properties $CONNECTED_CAR_DEMO/demo/data/connected_car/uber_bay_area_lat_lon.csv` (Note: To highlight StreamSets error handling abilities, the data generator is also capable of generating random records with bad values that the StreamSets pipeline will recognize and flag as errors. If you would like to turn on this functionality, append "-generateErrors" as the final argument to the data generator.)
7. Data should now be streaming in near real-time into the "connected_car_profiles" Kudu table and the "car-event-collection" Search collection, visualized in the Arcadia Data Dashboard (or Hue, if you want to explore it manually).
8. To reset the demo, run the setup.sh script (this will delete and recreate the Kudu table, both Kafka topics, and the Solr collection). `$ $CONNECTED_CAR_DEMO/demo/bin/setup.sh` (NOTE: Run as "root".)

## Arcadia Data Dashboard
Visit the Arcadia Data dashboard for this demo by navigating your browser to `<ARCADIA_HOST>:38888/arc/apps/appgroup/8` and logging in with admin/admin credentials.

Dashboard Notes:
- You want to view the dashboard as a "Standalone Application" (rather than clicking each screen individually from the App page). The easiest way to do this is to manually paste the URL above into your browser after logging into Arcadia Data. You can also open it as a standalone app by navigating to the "Apps" page, clicking on the connected car app group, and clicking "View Standalone App" near the top left of the screen.
- The dashboard is optimized to be viewed on a pretty large screen, so you may need to zoom your browser to make things fit best on a smaller screen.
- When on the "Event Stream" page, 5 second batch windows are being displayed and updating automatically. You will not see any data if you do not have the ingest pipeline (data generator, StreamSets, and Spark Streaming job) running.
- On the "Event Stream" page, you should click on a VIN from the list of events to be taken to the "Detailed View" page for that specific VIN.
- On the "Detailed View" page, click on a marker on the map to see more details about that event.
- The "Event Stream" page is geared towards use cases interested in real-time handling of events (e.g. a public safety org who wants to be notified when accidents occur so they can dispatch emergency response personnel).
- The "Analysis" page is geared towards use cases interested in analyzing overall behavior of drivers (e.g. auto manufacturers looking to make personalized recommendations, or insurance companies looking to identify high-risk drivers and/or assign personalized rates).
- The "Detailed View" page is a blend of looking at events and looking at overall driver behaviors, and might be relevant for, say, an insurance company investigating a specific driver.

## Delivery Assets
- See the powerpoint file in this directory.

