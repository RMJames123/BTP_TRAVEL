@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement - Consumption entity'
@Metadata.ignorePropagatedAnnotations: true

@Metadata.allowExtensions: true
@Search.searchable: true

define view entity Z_C_BKSUPPU_2893
  as projection on Z_R_BKSUPPU_2893
{
  key BookingsupplUuid,
      TravelUuid,
      BookingUuid,
      
      @Search.defaultSearchElement: true
      BookingSupplementId,

      @ObjectModel.text.element: [ 'SupplementDescription' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Supplement_StdVH',
                                                     element: 'SupplementID'},
                                           additionalBinding: [{ localElement: 'BookingSupplementPrice',
                                                                 element: 'Price',
                                                                 usage: #RESULT },
                                                               { localElement: 'CurrencyCode',
                                                                 element: 'CurrencyCode',
                                                                 usage: #RESULT }
                                                              ],
                                           useForValidation: true }]
      SupplementId,
      _SupplementText.Description as SupplementDescription : localized,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingSupplementPrice,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH',
                                                     element: 'Currency'},
                                           useForValidation: true }]
      CurrencyCode,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      /* Associations */
      _Booking : redirected to parent Z_C_BOOKNGU_2893,
      _Product,
      _SupplementText,
      _Travel  : redirected to Z_C_TRVLU_2893
}
