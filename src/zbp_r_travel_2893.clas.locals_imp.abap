CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    TYPES:
      ty_travel_create               TYPE TABLE FOR CREATE z_r_travel_2893\\Travel,
      ty_travel_update               TYPE TABLE FOR UPDATE z_r_travel_2893\\Travel,
      ty_travel_delete               TYPE TABLE FOR DELETE z_r_travel_2893\\Travel,
      ty_travel_failed               TYPE TABLE FOR FAILED EARLY z_r_travel_2893\\Travel,
      ty_travel_reported             TYPE TABLE FOR REPORTED EARLY z_r_travel_2893\\Travel,

      ty_travel_action_accept_import TYPE TABLE FOR ACTION IMPORT z_r_travel_2893\\Travel~acceptTravel,
      ty_travel_action_accept_result TYPE TABLE FOR ACTION RESULT z_r_travel_2893\\Travel~acceptTravel.

    CONSTANTS:
      BEGIN OF travel_status,
        open     TYPE c LENGTH 1 VALUE 'O',
        accepted TYPE c LENGTH 1 VALUE 'A',
        rejected TYPE c LENGTH 1 VALUE 'X',
      END OF travel_status.



    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS deductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Travel~deductDiscount RESULT result.

    METHODS reCalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~reCalcTotalPrice.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS Resume FOR MODIFY
      IMPORTING keys FOR ACTION Travel~Resume.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calculateTotalPrice.

    METHODS setStatusOpen FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setStatusOpen.

    METHODS setTravelNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~setTravelNumber.

    METHODS validateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateAgency.

    METHODS validateCurrencyCode FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCurrencyCode.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDates.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE Travel.

    METHODS precheck_auth
      IMPORTING
        entities_create TYPE ty_travel_create OPTIONAL
        entities_update TYPE ty_travel_update OPTIONAL
      CHANGING
        failed          TYPE ty_travel_failed
        reported        TYPE ty_travel_reported.


ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
       ENTITY Travel
       FIELDS ( OverallStatus )
       WITH CORRESPONDING #( keys )
       RESULT DATA(travels)
       FAILED failed.



    result  = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                               %field-BookingFee = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                           THEN if_abap_behv=>fc-f-read_only
                                                                           ELSE if_abap_behv=>fc-f-unrestricted )
                                               %action-acceptTravel =  COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                           THEN if_abap_behv=>fc-o-disabled
                                                                           ELSE if_abap_behv=>fc-o-enabled )
                                                %action-rejectTravel =  COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                                           THEN if_abap_behv=>fc-o-disabled
                                                                           ELSE if_abap_behv=>fc-o-enabled )
                                                %action-deductDiscount =  COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                           THEN if_abap_behv=>fc-o-disabled
                                                                           ELSE if_abap_behv=>fc-o-enabled )
                                                %assoc-_Booking =  COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                                           THEN if_abap_behv=>fc-o-disabled
                                                                           ELSE if_abap_behv=>fc-o-enabled ) ) ).



  ENDMETHOD.

  METHOD get_instance_authorizations.

    DATA: update_requested TYPE abap_bool,
          delete_requested TYPE abap_bool,
          update_granted   TYPE abap_bool,
          delete_granted   TYPE abap_bool.

    READ ENTITIES OF z_r_travel_2893 IN LOCAL MODE
      ENTITY Travel
        FIELDS ( AgencyID )
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels)
        FAILED failed.

    CHECK travels IS NOT INITIAL.

    "Decide business check
    DATA(lv_technical_user) = cl_abap_context_info=>get_user_technical_name(  ).

    update_requested = COND #( WHEN requested_authorizations-%update      = if_abap_behv=>mk-on
                                 OR requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                               THEN abap_true ELSE abap_false ).

    delete_requested = COND #( WHEN requested_authorizations-%delete      = if_abap_behv=>mk-on
                               THEN abap_true ELSE abap_false ).


    LOOP AT travels INTO DATA(travel).

      IF travel-AgencyID IS NOT INITIAL.

        "Business check
        IF lv_technical_user EQ 'CB9980002893' AND travel-AgencyID NE '70021'. "WHAT EVER.
          update_granted = delete_granted = abap_true.
*          delete_granted = abap_true.
        ELSE.
          update_granted = delete_granted = abap_false.
*           = abap_false.
        ENDIF.


        "check for update
        IF update_requested = abap_true.

          IF update_granted = abap_false.
            APPEND VALUE #( %tky = travel-%tky
                            %msg = NEW /dmo/cm_flight_messages(
                                                     textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                     agency_id = travel-AgencyID
                                                     severity  = if_abap_behv_message=>severity-error )
                            %element-AgencyID = if_abap_behv=>mk-on
                           ) TO reported-travel.
          ENDIF.
        ENDIF.

        "check for delete
        IF delete_requested = abap_true.

          IF delete_granted = abap_false.
            APPEND VALUE #( %tky = travel-%tky
                            %msg = NEW /dmo/cm_flight_messages(
                                     textid   = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                     agency_id = travel-AgencyID
                                     severity = if_abap_behv_message=>severity-error )
                            %element-AgencyID = if_abap_behv=>mk-on
                           ) TO reported-travel.
          ENDIF.
        ENDIF.

        " operations on draft instances and on active instances
        " new created instances
      ELSE.
        update_granted = delete_granted = abap_true. "REPLACE ME WITH BUSINESS CHECK
        IF update_granted = abap_false.
          APPEND VALUE #( %tky = travel-%tky
                          %msg = NEW /dmo/cm_flight_messages(
                                   textid   = /dmo/cm_flight_messages=>not_authorized
                                   severity = if_abap_behv_message=>severity-error )
                          %element-AgencyID = if_abap_behv=>mk-on
                        ) TO reported-travel.
        ENDIF.
      ENDIF.

*      data(upd_auth) = cond #( when update_granted = abap_true
*                               then if_abap_behv=>auth-allowed
*                               else if_abap_behv=>auth-unauthorized ).
*
*      data(del_auth) = cond #( when delete_granted = abap_true
*                               then if_abap_behv=>auth-allowed
*                               else if_abap_behv=>auth-unauthorized ).


      APPEND VALUE #(
                      LET upd_auth = COND #( WHEN update_granted = abap_true
                                             THEN if_abap_behv=>auth-allowed
                                             ELSE if_abap_behv=>auth-unauthorized )
                          del_auth = COND #( WHEN delete_granted = abap_true
                                             THEN if_abap_behv=>auth-allowed
                                             ELSE if_abap_behv=>auth-unauthorized )
                      IN
                       %tky = travel-%tky
                       %update                = upd_auth
                       %action-Edit           = del_auth

                       %delete                = del_auth
                    ) TO result.
    ENDLOOP.


  ENDMETHOD.

  METHOD get_global_authorizations.

    DATA(lv_technical_user) = cl_abap_context_info=>get_user_technical_name(  ).

    "lv_technical_user = 'ANOTHER'.

    IF requested_authorizations-%create EQ if_abap_behv=>mk-on.

      IF lv_technical_user EQ 'CB9980002893'.
        result-%create = if_abap_behv=>auth-allowed.
      ELSE.
        result-%create = if_abap_behv=>auth-unauthorized.

        APPEND VALUE #( %msg = NEW /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>not_authorized
                                     severity = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDIF.



    IF requested_authorizations-%update      EQ if_abap_behv=>mk-on OR
       requested_authorizations-%action-Edit EQ if_abap_behv=>mk-on.

      IF lv_technical_user EQ 'CB9980002893'.
        result-%update = if_abap_behv=>auth-allowed.
        result-%action-Edit = if_abap_behv=>auth-allowed.
      ELSE.
        result-%update = if_abap_behv=>auth-unauthorized.
        result-%action-Edit = if_abap_behv=>auth-unauthorized.

        APPEND VALUE #( %msg = NEW /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>not_authorized
                                     severity = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDIF.

    IF requested_authorizations-%delete EQ if_abap_behv=>mk-on.

      IF lv_technical_user EQ 'CB9980002893'.
        result-%delete = if_abap_behv=>auth-allowed.
      ELSE.
        result-%delete = if_abap_behv=>auth-unauthorized.

        APPEND VALUE #( %msg = NEW /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>not_authorized
                                     severity = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDIF.


  ENDMETHOD.

  METHOD acceptTravel.

    MODIFY ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
         ENTITY Travel
         UPDATE
         FIELDS ( OverallStatus )
         WITH VALUE #( FOR key IN keys ( %tky          = key-%tky
                                         OverallStatus = travel_status-accepted )  ).

    READ ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
         ENTITY Travel
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels (  %tky   = travel-%tky
                                               %param = travel ) ).


  ENDMETHOD.

  METHOD deductDiscount.

    DATA travels_for_update TYPE TABLE FOR UPDATE Z_r_TRAVEL_2893.

    DATA(keys_with_valid_discount) = keys.

    LOOP AT keys_with_valid_discount ASSIGNING FIELD-SYMBOL(<key_valid_discount>)
         WHERE %param-discount_percent IS INITIAL
            OR %param-discount_percent > 100
            OR %param-discount_percent <= 0.

      APPEND VALUE #( %tky = <key_valid_discount>-%tky ) TO failed-travel.

      APPEND VALUE #( %tky                     = <key_valid_discount>-%tky
                      %msg                       = NEW /dmo/cm_flight_messages(
                                                             textid   = /dmo/cm_flight_messages=>discount_invalid
                                                             severity = if_abap_behv_message=>severity-error )
                      %element-BookingFee        = if_abap_behv=>mk-on
                      %op-%action-deductDiscount = if_abap_behv=>mk-on ) TO reported-travel.

    ENDLOOP.

    CHECK failed-travel IS INITIAL.

    READ ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
           ENTITY Travel
           FIELDS ( BookingFee )
           WITH CORRESPONDING #( keys_with_valid_discount )
           RESULT DATA(travels).

    DATA percentage TYPE decfloat16.

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      DATA(discount_percent) = keys_with_valid_discount[ KEY id %tky = <travel>-%tky ]-%param-discount_percent.
      percentage = discount_percent / 100.
      DATA(reduce_fee) = <travel>-BookingFee * ( 1 - percentage ).

      APPEND VALUE #( %tky       = <travel>-%tky
                      BookingFee = reduce_fee ) TO travels_for_update.

    ENDLOOP.

    MODIFY ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
           ENTITY Travel
           UPDATE
           FIELDS ( BookingFee )
           WITH travels_for_update.

    READ ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
             ENTITY Travel
             ALL FIELDS
             WITH CORRESPONDING #( keys )
             RESULT DATA(travels_with_discount).

    result = VALUE #( FOR travel IN travels_with_discount (  %tky   = travel-%tky
                                                             %param = travel ) ).


  ENDMETHOD.

  METHOD reCalcTotalPrice.

    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA: amount_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.


    READ ENTITIES OF z_r_travel_2893 IN LOCAL MODE
         ENTITY Travel
         FIELDS ( BookingFee CurrencyCode )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DELETE travels WHERE CurrencyCode IS INITIAL.

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      amount_per_currencycode = VALUE #( ( amount        = <travel>-BookingFee
                                           currency_code = <travel>-CurrencyCode ) ).

      " Read Bookings
      READ ENTITIES OF z_r_travel_2893 IN LOCAL MODE
        ENTITY Travel BY \_Booking
          FIELDS ( FlightPrice CurrencyCode )
        WITH VALUE #( ( %tky = <travel>-%tky ) )
        RESULT DATA(bookings).

      LOOP AT bookings INTO DATA(booking) WHERE CurrencyCode IS NOT INITIAL.
        COLLECT VALUE ty_amount_per_currencycode( amount        = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode ) INTO amount_per_currencycode.
      ENDLOOP.

      " Read Booking Supplements
      READ ENTITIES OF z_r_travel_2893 IN LOCAL MODE
           ENTITY Booking BY \_BookingSupplement
           FIELDS ( BookingSupplementPrice CurrencyCode )
           WITH VALUE #( FOR rba_booking IN bookings ( %tky = rba_booking-%tky ) )
           RESULT DATA(bookingsupplements).

      LOOP AT bookingsupplements INTO DATA(bookingsupplement) WHERE CurrencyCode IS NOT INITIAL.
        COLLECT VALUE ty_amount_per_currencycode( amount        = bookingsupplement-BookingSupplementPrice
                                                  currency_code = bookingsupplement-CurrencyCode ) INTO amount_per_currencycode.
      ENDLOOP.

      CLEAR <travel>-TotalPrice.

      LOOP AT amount_per_currencycode INTO DATA(single_amount_per_currencycode).

        " Currency Conversion
        IF single_amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += single_amount_per_currencycode-amount.
        ELSE.
          /dmo/cl_flight_amdp=>convert_currency(
             EXPORTING
               iv_amount                   =  single_amount_per_currencycode-amount
               iv_currency_code_source     =  single_amount_per_currencycode-currency_code
               iv_currency_code_target     =  <travel>-CurrencyCode
               iv_exchange_rate_date       =  cl_abap_context_info=>get_system_date( )
             IMPORTING
               ev_amount                   = DATA(total_booking_price_per_curr)
            ).
          <travel>-TotalPrice += total_booking_price_per_curr.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " write back the modified total_price of travels
    MODIFY ENTITIES OF z_r_travel_2893 IN LOCAL MODE
      ENTITY travel
        UPDATE FIELDS ( TotalPrice )
        WITH CORRESPONDING #( travels ).


  ENDMETHOD.

  METHOD rejectTravel.

    MODIFY ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
       ENTITY Travel
       UPDATE
       FIELDS ( OverallStatus )
       WITH VALUE #( FOR key IN keys ( %tky          = key-%tky
                                       OverallStatus = travel_status-rejected )  ).

    READ ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
         ENTITY Travel
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels (  %tky   = travel-%tky
                                               %param = travel ) ).

  ENDMETHOD.

  METHOD Resume.
  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
    ENTITY Travel
    EXECUTE reCalcTotalPrice
    FROM CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD setStatusOpen.

    READ ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
         ENTITY Travel
         FIELDS ( OverallStatus )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DELETE travels WHERE OverallStatus IS NOT INITIAL.

    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
       ENTITY Travel
       UPDATE
       FIELDS ( OverallStatus )
       WITH VALUE #( FOR travel IN travels INDEX INTO i ( %tky          = travel-%tky
                                                          OverallStatus = travel_status-open )  ).


  ENDMETHOD.

  METHOD setTravelNumber.

*EML - Entity Manipulation Language
    READ ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
           ENTITY Travel
           FIELDS ( TravelID )
           WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    DELETE travels WHERE TravelID IS NOT INITIAL.

    CHECK travels IS NOT INITIAL.

    SELECT SINGLE FROM ztb_travel_2893
           FIELDS MAX( travel_id )
           INTO @DATA(lv_max_travelid).

    MODIFY ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
       ENTITY Travel
       UPDATE
       FIELDS ( TravelID )
       WITH VALUE #( FOR travel IN travels INDEX INTO i ( %tky     = travel-%tky
                                                          TravelID = lv_max_travelid + i )  ).


  ENDMETHOD.

  METHOD validateAgency.

    DATA agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY client agency_id.

    READ ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
         ENTITY Travel
         FIELDS ( AgencyID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    agencies = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING agency_id = AgencyID EXCEPT * ).
    DELETE agencies WHERE agency_id IS INITIAL.

    IF agencies IS NOT INITIAL.
      SELECT FROM /dmo/agency AS ddbb
             INNER JOIN @agencies AS http_req ON ddbb~agency_id EQ http_req~agency_id
             FIELDS ddbb~agency_id
             INTO TABLE @DATA(valid_agencies).
    ENDIF.

    LOOP AT travels INTO DATA(travel).

      IF travel-AgencyID IS INITIAL.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_AGENCY'
                        %msg                = NEW /dmo/cm_flight_messages(
                                                               textid   = /dmo/cm_flight_messages=>enter_agency_id
                                                               severity = if_abap_behv_message=>severity-error )
                        %element-AgencyID = if_abap_behv=>mk-on ) TO reported-travel.

      ELSEIF NOT line_exists( valid_agencies[ agency_id = travel-AgencyID ] ).

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_AGENCY'
                        %msg                = NEW /dmo/cm_flight_messages(
                                                               textid      = /dmo/cm_flight_messages=>agency_unkown
                                                               agency_id   = travel-AgencyID
                                                               severity    = if_abap_behv_message=>severity-error )
                        %element-AgencyID = if_abap_behv=>mk-on ) TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCurrencyCode.

    READ ENTITIES OF z_r_travel_2893 IN LOCAL MODE
     ENTITY Travel
     FIELDS ( CurrencyCode )
     WITH CORRESPONDING #( keys )
     RESULT DATA(travels).

    DATA currencies TYPE SORTED TABLE OF I_Currency WITH UNIQUE KEY Currency.

    currencies = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING Currency = CurrencyCode EXCEPT * ).
    DELETE currencies WHERE Currency IS INITIAL.

    IF currencies IS NOT INITIAL.

      SELECT FROM I_Currency AS ddbb
             INNER JOIN @currencies AS http_req ON ddbb~Currency = http_req~Currency
             FIELDS ddbb~Currency
             INTO TABLE @DATA(valid_currencies).

    ENDIF.


    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #( %tky        = travel-%tky
                      %state_area = 'VALIDATE_CURRENCIES' ) TO reported-travel.

      IF travel-CurrencyCode IS INITIAL.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CURRENCIES'
                        %msg = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>currency_required
                                                            severity = if_abap_behv_message=>severity-error )
                        %element-CurrencyCode    = if_abap_behv=>mk-on ) TO reported-travel.

      ELSEIF travel-CurrencyCode IS NOT INITIAL AND NOT line_exists( valid_currencies[ Currency = travel-CurrencyCode ] ).

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CURRENCIES'
                        %msg = NEW /dmo/cm_flight_messages( textid        = /dmo/cm_flight_messages=>currency_not_existing
                                                            severity      = if_abap_behv_message=>severity-error
                                                            currency_code = travel-CurrencyCode )
                        %element-CurrencyCode    = if_abap_behv=>mk-on ) TO reported-travel.

      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD validateCustomer.

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY client customer_id.

    READ ENTITIES OF Z_r_TRAVEL_2893 IN LOCAL MODE
         ENTITY Travel
         FIELDS ( CustomerID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).

    IF customers IS NOT INITIAL.
      SELECT FROM /dmo/customer AS ddbb
             INNER JOIN @customers AS http_req ON ddbb~customer_id EQ http_req~customer_id
             FIELDS ddbb~customer_id
             INTO TABLE @DATA(valid_customers).
    ENDIF.

    LOOP AT travels INTO DATA(travel).

      IF travel-CustomerID IS INITIAL.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = NEW /dmo/cm_flight_messages(
                                                               textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                               severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on ) TO reported-travel.

      ELSEIF travel-CustomerID IS NOT INITIAL AND NOT line_exists( valid_customers[ customer_id = travel-CustomerID ] ).

        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = NEW /dmo/cm_flight_messages(
                                                               textid      = /dmo/cm_flight_messages=>customer_unkown
                                                               customer_id = travel-CustomerID
                                                               severity    = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on ) TO reported-travel.

      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD validateDates.

    READ ENTITIES OF z_r_travel_2893 IN LOCAL MODE
         ENTITY Travel
         FIELDS (  BeginDate EndDate TravelID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #(  %tky               = travel-%tky
                       %state_area        = 'VALIDATE_DATES' ) TO reported-travel.

      IF travel-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = NEW /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
      IF travel-EndDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg                = NEW /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_end_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
      IF travel-EndDate < travel-BeginDate AND travel-BeginDate IS NOT INITIAL
                                           AND travel-EndDate IS NOT INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                                textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                                begin_date = travel-BeginDate
                                                                end_date   = travel-EndDate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
      IF travel-BeginDate < cl_abap_context_info=>get_system_date( ) AND travel-BeginDate IS NOT INITIAL.
        APPEND VALUE #( %tky               = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = NEW /dmo/cm_flight_messages(
                                                                begin_date = travel-BeginDate
                                                                textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD precheck_create.

    me->precheck_auth( EXPORTING entities_create = entities
                     CHANGING  failed          = failed-travel
                               reported        = reported-travel ).

  ENDMETHOD.

  METHOD precheck_update.

    me->precheck_auth( EXPORTING entities_update = entities
                      CHANGING  failed         = failed-travel
                                reported       = reported-travel ).

  ENDMETHOD.

  METHOD  precheck_auth.
  ENDMETHOD.

ENDCLASS.
