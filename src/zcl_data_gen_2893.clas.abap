CLASS zcl_data_gen_2893 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_data_gen_2893 IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DELETE FROM ztb_travel_2893.
    DELETE FROM ztb_travel_2893d.

    INSERT ztb_travel_2893 FROM (
    SELECT FROM /dmo/travel FIELDS
       uuid( ) AS travel_uuid,
     travel_id,
     agency_id,
     customer_id,
     begin_date,
     end_date,
     booking_fee,
     total_price,
     currency_code,
     description,
     CASE status
     WHEN 'B' THEN 'A'
     WHEN 'P' THEN 'O'
     WHEN 'N' THEN 'O'
     ELSE 'X' END AS overall_status,
     createdby AS local_created_by,
     createdat AS local_created_at,
     lastchangedby AS local_last_changed_by,
     lastchangedat AS local_last_changed_at
    ).

    IF sy-subrc EQ 0.
      out->write( |Travel:...{ sy-dbcnt } rows inserted.| ).
    ENDIF.

    DELETE FROM ztb_booking_2893.
    DELETE FROM ztb_booking2893d.

    INSERT ztb_booking_2893 FROM (
    SELECT FROM /dmo/booking
    JOIN ztb_travel_2893 ON /dmo/booking~travel_id = ztb_travel_2893~travel_id
    JOIN /dmo/travel ON /dmo/travel~travel_id = /dmo/booking~travel_id
    FIELDS
    uuid( ) AS booking_uuid,
    ztb_travel_2893~travel_uuid AS travel_uuid,
    /dmo/booking~booking_id,
    /dmo/booking~booking_date,
    /dmo/booking~customer_id,
    /dmo/booking~carrier_id,
    /dmo/booking~connection_id,
    /dmo/booking~flight_date,
    /dmo/booking~flight_price,
    /dmo/booking~currency_code,
    CASE /dmo/travel~status
    WHEN 'P' THEN 'N'
    ELSE /dmo/travel~status END AS booking_status,
    ztb_travel_2893~last_changed_at AS local_last_changed_at
).

    IF sy-subrc EQ 0.
      out->write( |Booking:...{ sy-dbcnt } rows inserted.| ).
    ENDIF.

    DELETE FROM ztb_bksuppl_2893.
    DELETE FROM ztb_bksuppl2893d.

    INSERT ztb_bksuppl_2893 FROM (
    SELECT FROM /dmo/book_suppl AS supp
    JOIN ztb_travel_2893 AS travel ON travel~travel_id = supp~travel_id
    JOIN ztb_booking_2893 AS book ON book~travel_uuid = travel~travel_uuid
    AND book~booking_id = supp~booking_id
    FIELDS
uuid( ) AS bookingsuppl_uuid,
travel~travel_uuid AS travel_uuid,
book~booking_uuid AS booking_uuid,
supp~booking_supplement_id,
supp~supplement_id,
supp~price,
supp~currency_code,
travel~last_changed_at AS local_last_changed_at
     ).

    IF sy-subrc EQ 0.
      out->write( |Booking Supplements:...{ sy-dbcnt } rows inserted.| ).
    ENDIF.


  ENDMETHOD.

ENDCLASS.
