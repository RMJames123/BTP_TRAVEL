@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement - Interface entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z_I_BKSUPPL_2893
  as projection on Z_R_BKSUPPL_2893
{
  key BookingsupplUuid,
      TravelUuid,
      BookingUuid,
      BookingSupplementId,
      SupplementId,
      
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingSupplementPrice,
      
      CurrencyCode,
      
      @Semantics.systemDateTime.lastChangedAt: true
      LocalLastChangedAt,
      
      /* Associations */
      _Booking : redirected to parent Z_I_BOOKING_2893,
      _Product,
      _SupplementText,
      _Travel : redirected to Z_I_TRAVEL_2893
}
