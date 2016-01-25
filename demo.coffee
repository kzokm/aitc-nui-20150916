Hue = require 'node-hue-api'
username = 'aitc-nui-20150916'

LIGHT_LIVING = 1
LIGHT_ENTRANCE = 2

LIVING_COUNT = 'http://aitc.dyndns.org/openmasami/record/latest/living/people'
ENTRANCE_COUNT = 'http://aitc.dyndns.org/openmasami/record/latest/entrance/people'
GUESTS_COUNT = 'http://aitc.dyndns.org/openmasami/record/latest/entrance/others'
LIVING_TEMP = encodeURI 'http://aitc.dyndns.org/openmasami/record/latest/1F/居間/温度'

MIN_BRIGHTNESS = 1
MAX_BRIGHTNESS = 254
MIN_HUE = 0
MAX_HUE = 65536
MIN_SATURATION = 0
MAX_SATURATION = 254

INTERVAL_MILLIS = 1000

Hue.upnpSearch()
  .then (bridges)->
    console.log bridges
    main new Hue.HueApi(bridges[0].ipaddress, username)
  .done()


main = (hue)->
  hue.version -> console.log arguments[1]
  for i in [1..3]
    hue.setLightState i, { on: false }

  request = require 'request'
  watch = (url, action)->
    previous = undefined
    watchdog = ->
      request url, (error, response, body)->
        data = JSON.parse body
        if data.length > 0
          value = (parseInt data[0]) || 0
          if value != previous
            console.log url, body
            action value, previous
            previous = value
      setTimeout watchdog, INTERVAL_MILLIS
    watchdog()

  watch LIVING_COUNT, (numPeople)->
    if numPeople == 0
      hue.setLightState LIGHT_LIVING,
        on: false
    else
      brightness = Math.min numPeople * 100, MAX_BRIGHTNESS
      hue.setLightState LIGHT_LIVING,
        on: true
        bri: brightness

  watch LIVING_TEMP, (temp)->
    temp = Math.max 0, temp
    hue.setLightState LIGHT_LIVING,
      hue: temp * 1000
      sat: 150 - temp

  watch ENTRANCE_COUNT, (numPeople)->
    if numPeople == 0
      hue.setLightState LIGHT_ENTRANCE,
        on: false
    else
      brightness = Math.min numPeople * 100, MAX_BRIGHTNESS
      hue.setLightState LIGHT_ENTRANCE,
        on: true
        bri: brightness
        hue: 30000
        sat: 0

  watch GUESTS_COUNT, (numPeople)->
    if numPeople == 0
      hue.setLightState LIGHT_ENTRANCE,
        on: false
      hue.setLightState LIGHT_LIVING,
        alert: 'none'
    else
      hue.setLightState LIGHT_ENTRANCE,
        on: true
      hue.setLightState LIGHT_LIVING,
        alert: 'lselect'
