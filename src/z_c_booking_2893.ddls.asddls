@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Consumption Entity'
@Metadata.ignorePropagatedAnnotations: true

@Metadata.allowExtensions: true
@Search.searchable: true

define view entity Z_C_BOOKING_2893
  as projection on Z_R_BOOKING_2893
{
  key BookingUuid,
      TravelUuid,
      
      @Search.defaultSearchElement: true
      BookingId,
      BookingDate,
      
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Customer_StdVH',
                                                     element: 'CustomerID'},
                                           useForValidation: true }]     
      CustomerId,
      _Customer.LastName as CustomerName,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'CarrierName' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Flight_StdVH',
                                                     element: 'AirlineID'},
                                           additionalBinding: [{ localElement: 'ConnectionId',
                                                                 element: 'ConnectionID',
                                                                 usage: #RESULT },
                                                               { localElement: 'FlightDate',
                                                                 element: 'FlightDate',
                                                                 usage: #RESULT },
                                                               { localElement: 'FlightPrice',
                                                                 element: 'Price',
                                                                 usage: #RESULT },
                                                               { localElement: 'CurrencyCode',
                                                                 element: 'CurrencyCode',
                                                                 usage: #RESULT }                                                                                                                                                                                                   
                                                              ],
                                           useForValidation: true }]    
      AirlineId,
      _Carrier.Name as CarrierName,

      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Flight_StdVH',
                                                     element: 'ConnectionID'},
                                           additionalBinding: [{ localElement: 'AirlineId',
                                                                 element: 'AirlineID',
                                                                 usage: #FILTER_AND_RESULT },
                                                               { localElement: 'FlightDate',
                                                                 element: 'FlightDate',
                                                                 usage: #RESULT },
                                                               { localElement: 'FlightPrice',
                                                                 element: 'Price',
                                                                 usage: #RESULT },
                                                               { localElement: 'CurrencyCode',
                                                                 element: 'CurrencyCode',
                                                                 usage: #RESULT }                                                                                                                                                                                                   
                                                              ],
                                           useForValidation: true }]
      ConnectionId,

      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Flight_StdVH',
                                                     element: 'FlightDate'},
                                           additionalBinding: [{ localElement: 'AirlineId',
                                                                 element: 'AirlineID',
                                                                 usage: #FILTER_AND_RESULT },
                                                               { localElement: 'ConnectionId',
                                                                 element: 'ConnectionID',
                                                                 usage: #FILTER_AND_RESULT },
                                                               { localElement: 'FlightPrice',
                                                                 element: 'Price',
                                                                 usage: #RESULT },
                                                               { localElement: 'CurrencyCode',
                                                                 element: 'CurrencyCode',
                                                                 usage: #RESULT }                                                                                                                                                                                                   
                                                              ],
                                           useForValidation: true }]
      FlightDate,
      
      @Semantics.amount.currencyCode: 'CurrencyCode'

      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Flight_StdVH',
                                                     element: 'Price'},
                                           additionalBinding: [{ localElement: 'FlightDate',
                                                                 element: 'FlightDate',
                                                                 usage: #FILTER_AND_RESULT },
                                                               { localElement: 'ConnectionId',
                                                                 element: 'ConnectionID',
                                                                 usage: #FILTER_AND_RESULT },
                                                               { localElement: 'AirlineId',
                                                                 element: 'AirlineID',
                                                                 usage: #RESULT },
                                                               { localElement: 'CurrencyCode',
                                                                 element: 'CurrencyCode',
                                                                 usage: #RESULT }                                                                                                                                                                                                   
                                                              ],
                                           useForValidation: true }]

      FlightPrice,
      
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH',
                                                     element: 'Currency'},
                                           useForValidation: true }]
      CurrencyCode,

      @ObjectModel.text.element: [ 'BookingStatusText' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Booking_Status_VH',
                                                     element: 'BookingStatus'},
                                           useForValidation: true }]
      BookingStatus,
      _BookingStatus._Text.Text as BookingStatusText : localized,
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      
      /* Associations */
      _BookingStatus,
      _BookingSupplement : redirected to composition child Z_C_BKSUPPL_2893,
      _Carrier,
      _Connection,
      _Customer,
      _Travel : redirected to parent Z_C_TRAVEL_2893
}
