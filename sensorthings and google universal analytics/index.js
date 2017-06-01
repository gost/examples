"use strict"

let UA_KEY = 'UA-100244452-1'
var ua = require('universal-analytics');
let visitor = ua(UA_KEY);
const mqtt = require('mqtt')  
const client = mqtt.connect('tcp://gost.geodan.nl:1883')

client.on('connect', () => {  
  client.subscribe('Datastreams(58)/Observations')
}) 

client.on('message', (topic, message) => {
    var value = JSON.parse(message.toString()).result;  
    console.log('New message!', value)
    SendToGoogle(value);
});

function SendToGoogle(value){
    visitor.event('sensor 58', value,function (err){
        if (err) return console.log("error:" + err);
        console.log('Sent event to GA', '58', value);
    }).send();
}
