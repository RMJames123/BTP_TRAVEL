@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z_I_BOOKING_2893
  as projection on Z_R_BOOKING_2893
{
  key BookingUuid,
      TravelUuid,
      BookingId,
      BookingDate,
      CustomerId,
      AirlineId,
      ConnectionId,
      FlightDate,
      
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      
      CurrencyCode,
      BookingStatus,
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      
      /* Associations */
      _BookingStatus,
      _BookingSupplement : redirected to composition child Z_I_BKSUPPL_2893,
      _Carrier,
      _Connection,
      _Customer,
      _Travel : redirected to parent Z_I_TRAVEL_2893
}
