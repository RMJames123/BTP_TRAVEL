@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement - root entity'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Z_R_BKSUPPL_2893
  as select from ztb_bksuppl_2893

  association        to parent Z_R_BOOKING_2893 as _Booking        on $projection.BookingUuid = _Booking.BookingUuid
  association [1..1] to Z_R_TRAVEL_2893         as _Travel         on $projection.TravelUuid = _Travel.TravelUuid

  association [1..1] to /DMO/I_Supplement       as _Product        on $projection.SupplementId = _Product.SupplementID
  association [1..*] to /DMO/I_SupplementText   as _SupplementText on $projection.SupplementId = _SupplementText.SupplementID

{
  key bookingsuppl_uuid        as BookingsupplUuid,
      travel_uuid              as TravelUuid,
      booking_uuid             as BookingUuid,

      booking_supplement_id    as BookingSupplementId,
      supplement_id            as SupplementId,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_supplement_price as BookingSupplementPrice,

      currency_code            as CurrencyCode,

      //Local ETag - OData
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at    as LocalLastChangedAt,

      _Booking,
      _Travel,
      _Product,
      _SupplementText
}
