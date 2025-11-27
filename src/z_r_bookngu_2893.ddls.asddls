@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking - root entity'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Z_R_BOOKNGU_2893

  as select from ztb_booking_2893

 association        to parent Z_R_TRVLU_2893   as _Travel        on  $projection.TravelUuid = _Travel.TravelUuid

  composition [0..*] of Z_R_BKSUPPU_2893         as _BookingSupplement

  association [1..1] to /DMO/I_Customer          as _Customer      on  $projection.CustomerId = _Customer.CustomerID
  association [1..1] to /DMO/I_Carrier           as _Carrier       on  $projection.AirlineId = _Carrier.AirlineID
  association [1..1] to /DMO/I_Connection        as _Connection    on  $projection.AirlineId    = _Connection.AirlineID
                                                                   and $projection.ConnectionId = _Connection.ConnectionID
  association [1..1] to /DMO/I_Booking_Status_VH as _BookingStatus on  $projection.BookingStatus = _BookingStatus.BookingStatus

{
  key booking_uuid          as BookingUuid,
      travel_uuid           as TravelUuid,
      
      booking_id            as BookingId,
      booking_date          as BookingDate,
      customer_id           as CustomerId,
      airline_id            as AirlineId,
      connection_id         as ConnectionId,
      flight_date           as FlightDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price          as FlightPrice,
      currency_code         as CurrencyCode,
      booking_status        as BookingStatus,

      //Local ETag - OData
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      //concat_with_space( _Customer.LastName, _Customer.FirstName, 1 ) as CustomerName,

      _Travel,
      _BookingSupplement,
      _Customer,
      _Carrier,
      _Connection,
      _BookingStatus

}
