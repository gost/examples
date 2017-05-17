CREATE OR REPLACE FUNCTION notifygost() RETURNS TRIGGER AS $BODY$
    BEGIN
	PERFORM pg_notify('observation_insert',
		json_build_object('id', a.gost_streamid, 'result', array_sum(NEW.vehicleflow))::text
		)
	FROM ndw.mst a
        WHERE NEW.location = a.mst_id;
        RETURN new;
    END;
$BODY$ LANGUAGE plpgsql;

DROP TRIGGER ndw_streaminsrt ON ndw.tmp;
CREATE TRIGGER ndw_streaminsrt AFTER INSERT ON ndw.trafficspeed
FOR EACH ROW EXECUTE PROCEDURE notifygost();

INSERT INTO ndw.tmp VALUES ('PUT02_701D-701-701',now(),ARRAY[100,90,50],ARRAY[100,900,500]);

