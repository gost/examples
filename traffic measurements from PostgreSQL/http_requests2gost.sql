/* 
	This script creates GOST entities based on data from the ndw.mst and ndw.trafficspeed tables
*/


SET http.keepalive = 'on';
/*Things*/
UPDATE ndw.mst a SET gost_thingid = (content::json ->> '@iot.id')::int
FROM (SELECT * FROM ndw.mst) c
LEFT JOIN LATERAL http_post('http://gost.geodan.nl/v1.0/Things',
                 '{
    "description": " '|| c.mst_id || '",
    "properties": {
	"equipment": "'||c.equipment ||'",
        "organisation": "Geodan",
        "owner": "Tom"
    }
}',
'application/json') b
ON true
WHERE a.gid = c.gid
;

SET http.keepalive = 'on';
/*Locations*/
UPDATE ndw.mst a SET gost_locationid = (content::json ->> '@iot.id')::int
FROM (SELECT * FROM ndw.mst) c
LEFT JOIN LATERAL http_post('http://gost.geodan.nl/v1.0/Things('||c.gost_thingid||')/Locations',
                 '{
    "description": " '|| c.mst_id || '",
    "encodingType": "application/vnd.geo+json",
    "location": {
        "type": "Point",
        "coordinates": ['|| ST_X(c.geom)||','||
        ST_Y(c.geom)||']
    }
}',
'application/json') b
ON true
WHERE a.gid = c.gid;

SET http.keepalive = 'on';
/*Observed properties */
WITH obsprop AS (
	SELECT (content::json ->> '@iot.id')::int AS id 
	FROM http_post('http://gost.geodan.nl/v1.0/ObservedProperties','{
	  "name": "num_vehicles",
	  "description": "Number of vehicles passing per minute",
	  "definition": "http://opendata.ndw.nu/"
	}','application/json')
)
,
/* Sensors */
sensor AS (
	SELECT (content::json ->> '@iot.id')::int AS id 
	FROM http_post('http://gost.geodan.nl/v1.0/Sensors','{        
	    "description": "Inductionloop",
	    "encodingType": "application/pdf",
	    "metadata": "https://en.wikipedia.org/wiki/Induction_loop"
	}','application/json')
)
/* Datastreams */
UPDATE ndw.mst a SET gost_streamid = (content::json ->> '@iot.id')::int
FROM (SELECT * FROM ndw.mst) c, obsprop, sensor
LEFT JOIN LATERAL http_post('http://gost.geodan.nl/v1.0/Datastreams',
'{
    "unitOfMeasurement": {
        "symbol": "Num",
        "name": "Num vehicles",
        "definition": "http://unitsofmeasure.org/ucum.html#para-30"
    },
  "observationType":"http://www.opengis.net/def/observationType/OGC-OM/2.0/OM_Measurement",
  "description": "Inductionloop readings",
  "Thing": {"@iot.id": '||c.gost_thingid||'},
  "ObservedProperty": {"@iot.id": '||obsprop.id||'},
  "Sensor": {"@iot.id": '||sensor.id||'}
}',
'application/json') b
ON true
WHERE a.gid = c.gid;
SET http.keepalive = 'off';

