# hyperionESPNode
Lua code for nodemcu to create a [hyperion](https://github.com/hyperion-project/hyperion) server

* Control your ws2812b led strip with an ESP8266 module
* Tested with [D1mini](http://www.wemos.cc/Products/d1_mini.html)

* Support for **Home Assistant** **MQTT JSON Light**

  Configuration:
  ```yaml
  light:
    - platform: mqtt_json
      state_topic: TOPIC/rgb
      command_topic: TOPIC/rgb/set
      rgb: true
      brightness: true
      availability_topic: TOPIC/status
      payload_available: 1
      payload_not_available: 0
  ```

![](doc/foto.jpg?raw "Foto")
