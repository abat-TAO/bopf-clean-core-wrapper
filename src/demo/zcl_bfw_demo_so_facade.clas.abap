class ZCL_BFW_DEMO_SO_FACADE definition
  public
  final
  create public .

public section.

  methods CONSTRUCTOR .
  methods CREATE_ITEM
    exporting
      !FAILED_KEYS type /BOBF/T_FRW_KEY
      !MESSAGES type ZIF_BFW_BUSINESS_OBJECT=>MESSAGES
    changing
      !ROWS type /BOBF/T_DEMO_SALES_ORDER_ITM_K .
  methods DELETE_ITEM
    importing
      !KEYS type /BOBF/T_FRW_KEY
    exporting
      !FAILED_KEYS type /BOBF/T_FRW_KEY
      !MESSAGES type ZIF_BFW_BUSINESS_OBJECT=>MESSAGES .
  methods EXECUTE_ARCHIVE
    importing
      !KEYS type /BOBF/T_FRW_KEY optional
    exporting
      !FAILED_KEYS type /BOBF/T_FRW_KEY
      !MESSAGES type ZIF_BFW_BUSINESS_OBJECT=>MESSAGES .
  methods EXECUTE_DELIVER
    importing
      !KEYS type /BOBF/T_FRW_KEY optional
      !PARAMETERS type /BOBF/S_DEMO_SALES_ORDER_HDR_D optional
    exporting
      !FAILED_KEYS type /BOBF/T_FRW_KEY
      !MESSAGES type ZIF_BFW_BUSINESS_OBJECT=>MESSAGES .
  class-methods GET_SELECTION
    returning
      value(RESULT) type STRING_TABLE .
  methods QUERY_SELECT_ALL
    importing
      !FILTER_KEYS type /BOBF/T_FRW_KEY optional
      !MAXIMUM_ROWS type I default 0
      !PAGING type ZIF_BFW_BUSINESS_OBJECT=>PAGING optional
      !SELECTION_PARAMETERS type ZIF_BFW_BUSINESS_OBJECT=>SELECTION_PARAMETERS optional
      !SORTING type ZIF_BFW_BUSINESS_OBJECT=>SORTING optional
    returning
      value(RESULT) type /BOBF/T_DEMO_SALES_ORDER_HDR_K .
  methods QUERY_SELECT_BY_ELEMENTS
    importing
      !FILTER_KEYS type /BOBF/T_FRW_KEY optional
      !MAXIMUM_ROWS type I default 0
      !PAGING type ZIF_BFW_BUSINESS_OBJECT=>PAGING optional
      !SELECTION_PARAMETERS type ZIF_BFW_BUSINESS_OBJECT=>SELECTION_PARAMETERS optional
      !SORTING type ZIF_BFW_BUSINESS_OBJECT=>SORTING optional
    returning
      value(RESULT) type /BOBF/T_DEMO_SALES_ORDER_HDR_K .
  methods READ_CUSTOMERS
    importing
      !KEYS type /BOBF/T_FRW_KEY
    returning
      value(RESULT) type /BOBF/T_DEMO_CUSTOMER_HDR_K .
  methods READ_ITEM
    importing
      !KEYS type /BOBF/T_FRW_KEY
    returning
      value(RESULT) type /BOBF/T_DEMO_SALES_ORDER_ITM_K .
  methods READ_ITEMS
    importing
      !KEYS type /BOBF/T_FRW_KEY
    returning
      value(RESULT) type /BOBF/T_DEMO_SALES_ORDER_ITM_K .
  methods READ_ITEM_PRODUCT_ROOT
    importing
      !KEYS type /BOBF/T_FRW_KEY
    returning
      value(RESULT) type /BOBF/T_DEMO_PRODUCT_HDR_K .
  methods READ_ORDERS_BY_ID
    importing
      !VALUES type /BOBF/T_DEMO_SALES_ORDER_ID
    returning
      value(RESULT) type /BOBF/T_DEMO_SALES_ORDER_HDR_K .
  methods READ_ROOT
    importing
      !KEYS type /BOBF/T_FRW_KEY
    returning
      value(RESULT) type /BOBF/T_DEMO_SALES_ORDER_HDR_K .
  methods READ_ROOT_LONG_TEXT_CONTENT
    importing
      !KEYS type /BOBF/T_FRW_KEY
    returning
      value(RESULT) type /BOBF/T_DEMO_LONGTEXT_ITEM_K .
  methods READ_ROOT_ROOT_LONG_TEXT
    importing
      !KEYS type /BOBF/T_FRW_KEY
    returning
      value(RESULT) type /BOBF/T_DEMO_LONGTEXT_HDR_K .
  methods READ_ROOT_ROOT_TEXT
    importing
      !FILTER type /BOBF/S_DEMO_LANGUAGE_CODE optional
      !KEYS type /BOBF/T_FRW_KEY
    returning
      value(RESULT) type /BOBF/T_DEMO_SHORT_TEXT_K .
  methods READ_ROOT_TEXT
    importing
      !KEYS type /BOBF/T_FRW_KEY
    returning
      value(RESULT) type /BOBF/T_DEMO_SHORT_TEXT_K .
  methods UPDATE_ITEM
    importing
      !CHANGED_FIELDS type ZIF_BFW_BUSINESS_OBJECT=>FIELD_NAMES optional
      !ROWS type /BOBF/T_DEMO_SALES_ORDER_ITM_K
    exporting
      !FAILED_KEYS type /BOBF/T_FRW_KEY
      !MESSAGES type ZIF_BFW_BUSINESS_OBJECT=>MESSAGES .
protected section.
private section.

  data ENGINE type ref to ZIF_BFW_BUSINESS_OBJECT .
ENDCLASS.



CLASS ZCL_BFW_DEMO_SO_FACADE IMPLEMENTATION.


  method CONSTRUCTOR.
    engine = zcl_bfw_factory=>get_business_object( `/BOBF/DEMO_SALES_ORDER` ).
  endmethod.


  method CREATE_ITEM.
    DATA engine_failed_keys TYPE zif_bfw_business_object=>keys.

    engine->create( EXPORTING node        = `ITEM`
                    IMPORTING failed_keys = engine_failed_keys
                              messages    = messages
                    CHANGING  rows        = rows ).
    failed_keys = CORRESPONDING #( engine_failed_keys ).
  endmethod.


  method DELETE_ITEM.
    DATA engine_failed_keys TYPE zif_bfw_business_object=>keys.

    engine->delete( EXPORTING node        = `ITEM`
                              keys        = CORRESPONDING #( keys )
                    IMPORTING failed_keys = engine_failed_keys
                              messages    = messages ).
    failed_keys = CORRESPONDING #( engine_failed_keys ).
  endmethod.


  method EXECUTE_ARCHIVE.
    DATA engine_failed_keys TYPE zif_bfw_business_object=>keys.

    engine->execute_action( EXPORTING node        = `ROOT`
                                      action      = `ARCHIVE`
                                      keys        = CORRESPONDING #( keys )
                            IMPORTING failed_keys = engine_failed_keys
                                      messages    = messages ).
    failed_keys = CORRESPONDING #( engine_failed_keys ).
  endmethod.


  method EXECUTE_DELIVER.
    DATA engine_failed_keys TYPE zif_bfw_business_object=>keys.

    engine->execute_action( EXPORTING node        = `ROOT`
                                      action      = `DELIVER`
                                      keys        = CORRESPONDING #( keys )
                                      parameters  = parameters
                            IMPORTING failed_keys = engine_failed_keys
                                      messages    = messages ).
    failed_keys = CORRESPONDING #( engine_failed_keys ).
  endmethod.


  method GET_SELECTION.
    " Generated by ZBFW_FACADE_GENERATOR: do not change, regenerate instead
    result = VALUE #( ( `node ROOT` )
                      ( `node ITEM` )
                      ( `node ROOT_TEXT` )
                      ( `node ROOT_LONG_TEXT.CONTENT` )
                      ( `writable_node ITEM` )
                      ( `association ROOT.ITEM = items` )
                      ( `association ROOT.CUSTOMER_ROOT = customers` )
                      ( `association ROOT.ROOT_LONG_TEXT` )
                      ( `association ROOT.ROOT_TEXT` )
                      ( `association ITEM.PRODUCT_ROOT` )
                      ( `alternative_key ROOT.ORDER_ID = orders_by_id` )
                      ( `query ROOT.SELECT_ALL` )
                      ( `query ROOT.SELECT_BY_ELEMENTS` )
                      ( `action ROOT.DELIVER` )
                      ( `action ROOT.ARCHIVE` ) ).
  endmethod.


  method QUERY_SELECT_ALL.
    engine->query( EXPORTING node                 = `ROOT`
                             query                = `SELECT_ALL`
                             selection_parameters = selection_parameters
                             filter_keys          = CORRESPONDING #( filter_keys )
                             maximum_rows         = maximum_rows
                             sorting              = sorting
                             paging               = paging
                   IMPORTING rows                 = result ).
  endmethod.


  method QUERY_SELECT_BY_ELEMENTS.
    engine->query( EXPORTING node                 = `ROOT`
                             query                = `SELECT_BY_ELEMENTS`
                             selection_parameters = selection_parameters
                             filter_keys          = CORRESPONDING #( filter_keys )
                             maximum_rows         = maximum_rows
                             sorting              = sorting
                             paging               = paging
                   IMPORTING rows                 = result ).
  endmethod.


  method READ_CUSTOMERS.
    engine->read_by_association( EXPORTING node        = `ROOT`
                                           association = `CUSTOMER_ROOT`
                                           keys        = CORRESPONDING #( keys )
                                 IMPORTING rows        = result ).
  endmethod.


  method READ_ITEM.
    engine->read( EXPORTING node = `ITEM`
                            keys = CORRESPONDING #( keys )
                  IMPORTING rows = result ).
  endmethod.


  method READ_ITEMS.
    engine->read_by_association( EXPORTING node        = `ROOT`
                                           association = `ITEM`
                                           keys        = CORRESPONDING #( keys )
                                 IMPORTING rows        = result ).
  endmethod.


  method READ_ITEM_PRODUCT_ROOT.
    engine->read_by_association( EXPORTING node        = `ITEM`
                                           association = `PRODUCT_ROOT`
                                           keys        = CORRESPONDING #( keys )
                                 IMPORTING rows        = result ).
  endmethod.


  method READ_ORDERS_BY_ID.
    engine->convert_alternative_key( EXPORTING node            = `ROOT`
                                               alternative_key = `ORDER_ID`
                                               values          = values
                                     IMPORTING rows            = result ).
  endmethod.


  method READ_ROOT.
    engine->read( EXPORTING node = `ROOT`
                            keys = CORRESPONDING #( keys )
                  IMPORTING rows = result ).
  endmethod.


  method READ_ROOT_LONG_TEXT_CONTENT.
    engine->read( EXPORTING node = `ROOT_LONG_TEXT.CONTENT`
                            keys = CORRESPONDING #( keys )
                  IMPORTING rows = result ).
  endmethod.


  method READ_ROOT_ROOT_LONG_TEXT.
    engine->read_by_association( EXPORTING node        = `ROOT`
                                           association = `ROOT_LONG_TEXT`
                                           keys        = CORRESPONDING #( keys )
                                 IMPORTING rows        = result ).
  endmethod.


  method READ_ROOT_ROOT_TEXT.
    engine->read_by_association( EXPORTING node        = `ROOT`
                                           association = `ROOT_TEXT`
                                           keys        = CORRESPONDING #( keys )
                                           filter      = filter
                                 IMPORTING rows        = result ).
  endmethod.


  method READ_ROOT_TEXT.
    engine->read( EXPORTING node = `ROOT_TEXT`
                            keys = CORRESPONDING #( keys )
                  IMPORTING rows = result ).
  endmethod.


  method UPDATE_ITEM.
    DATA engine_failed_keys TYPE zif_bfw_business_object=>keys.

    engine->update( EXPORTING node           = `ITEM`
                              rows           = rows
                              changed_fields = changed_fields
                    IMPORTING failed_keys    = engine_failed_keys
                              messages       = messages ).
    failed_keys = CORRESPONDING #( engine_failed_keys ).
  endmethod.
ENDCLASS.
