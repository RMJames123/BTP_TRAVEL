@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_TRVLU_2893
  provider contract transactional_interface
  as projection on Z_R_TRVLU_2893
{
  key TravelUuid,
      TravelId,
      AgencyId,
      CustomerId,
      BeginDate,
      EndDate,
      
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      
      CurrencyCode,
      Description,
      OverallStatus,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      
      /* Associations */
      _Agency,
      _Booking : redirected to composition child Z_I_BOOKNGU_2893,
      _Currency,
      _Customer,
      _OverallStatus
}
