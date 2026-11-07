"! Access to the BOPF demo sales order through the wrapper and the mapping of its messages to the RAP response
CLASS lcl_sales_order DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES:
      "! Root fields of the RAP entity, named as in the BOPF node so that the wrapper maps them
      BEGIN OF root_row,
        key             TYPE zif_bfw_business_object=>instance_key,
        order_id        TYPE /bobf/demo_sales_order_id,
        customer_id     TYPE /bobf/demo_customer_id,
        sales_org       TYPE /bobf/demo_sales_org,
        amount          TYPE /bobf/demo_total_amount,
        amount_curr     TYPE /bobf/demo_currency,
        delivery_status TYPE /bobf/demo_sales_order_dlv_mod,
      END OF root_row,
      root_rows TYPE STANDARD TABLE OF root_row WITH EMPTY KEY.

    TYPES reported_early TYPE RESPONSE FOR REPORTED EARLY zbfw_r_demoorder.
    TYPES reported_late TYPE RESPONSE FOR REPORTED LATE zbfw_r_demoorder.
    TYPES failed_late TYPE RESPONSE FOR FAILED LATE zbfw_r_demoorder.

    CLASS-METHODS get
      RETURNING
        VALUE(result) TYPE REF TO zif_bfw_business_object.

    "! Messages of the handlers
    CLASS-METHODS report
      IMPORTING
        messages TYPE zif_bfw_business_object=>messages
      CHANGING
        reported TYPE reported_early.

    "! Messages of the saver
    CLASS-METHODS report_late
      IMPORTING
        messages TYPE zif_bfw_business_object=>messages
      CHANGING
        reported TYPE reported_late.

    CLASS-METHODS fail_refused_save
      IMPORTING
        messages TYPE zif_bfw_business_object=>messages
      CHANGING
        failed   TYPE failed_late.

    CLASS-METHODS remember_change
      IMPORTING
        key TYPE zif_bfw_business_object=>instance_key.

    CLASS-METHODS forget_changes.

  PRIVATE SECTION.
    "! Instances changed in the current transaction; they fail as a whole when BOPF refuses the save without naming them
    CLASS-DATA changed_keys TYPE zif_bfw_business_object=>keys.
ENDCLASS.


CLASS lcl_sales_order IMPLEMENTATION.

  METHOD get.
    result = zcl_bfw_factory=>get_business_object( `/BOBF/DEMO_SALES_ORDER` ).
  ENDMETHOD.


  METHOD report.
    DATA(rap_messages) = zcl_bfw_rap_message=>from_messages( messages ).
    LOOP AT rap_messages ASSIGNING FIELD-SYMBOL(<rap_message>).
      " Messages of a root instance belong to the RAP instance, all others to the transaction
      IF <rap_message>-node = `ROOT` AND <rap_message>-key IS NOT INITIAL.
        INSERT VALUE #( OrderKey = <rap_message>-key
                        %msg     = <rap_message>-message ) INTO TABLE reported-order.
      ELSE.
        INSERT <rap_message>-message INTO TABLE reported-%other.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD report_late.
    DATA(rap_messages) = zcl_bfw_rap_message=>from_messages( messages ).
    LOOP AT rap_messages ASSIGNING FIELD-SYMBOL(<rap_message>).
      IF <rap_message>-node = `ROOT` AND <rap_message>-key IS NOT INITIAL.
        INSERT VALUE #( OrderKey = <rap_message>-key
                        %msg     = <rap_message>-message ) INTO TABLE reported-order.
      ELSE.
        INSERT <rap_message>-message INTO TABLE reported-%other.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD fail_refused_save.
    " Root instances with an error fail; if BOPF names none, all instances changed in the transaction fail
    DATA(failed_keys) = VALUE zif_bfw_business_object=>keys(
                          FOR entry IN messages WHERE ( node = `ROOT` AND key IS NOT INITIAL AND severity CA 'EA' )
                          ( key = entry-key ) ).
    IF failed_keys IS INITIAL.
      failed_keys = changed_keys.
    ENDIF.
    SORT failed_keys BY key.
    DELETE ADJACENT DUPLICATES FROM failed_keys COMPARING key.
    LOOP AT failed_keys ASSIGNING FIELD-SYMBOL(<failed_key>).
      INSERT VALUE #( OrderKey = <failed_key>-key ) INTO TABLE failed-order.
    ENDLOOP.
  ENDMETHOD.


  METHOD remember_change.
    INSERT VALUE #( key = key ) INTO TABLE changed_keys.
  ENDMETHOD.


  METHOD forget_changes.
    CLEAR changed_keys.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_order DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Order RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Order.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Order.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Order.

    METHODS read FOR READ
      IMPORTING keys FOR READ Order RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Order.
ENDCLASS.


CLASS lhc_order IMPLEMENTATION.

  METHOD get_global_authorizations.
    " The demo allows every requested operation; the BOPF business object checks its own authorizations
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      result-%delete = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.


  METHOD create.
    DATA row TYPE lcl_sales_order=>root_row.

    " BOPF draws the keys of the new instances and writes them back into the rows
    DATA(rows) = VALUE lcl_sales_order=>root_rows( FOR new_order IN entities
                                                  ( order_id    = new_order-OrderId
                                                    customer_id = new_order-CustomerId
                                                    sales_org   = new_order-SalesOrganization
                                                    amount      = new_order-Amount
                                                    amount_curr = new_order-Currency ) ).
    lcl_sales_order=>get( )->create( EXPORTING node        = `ROOT`
                                     IMPORTING failed_keys = DATA(failed_keys)
                                               messages    = DATA(messages)
                                     CHANGING  rows        = rows ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      row = rows[ sy-tabix ].
      IF line_exists( failed_keys[ key = row-key ] ).
        INSERT VALUE #( %cid = <entity>-%cid ) INTO TABLE failed-order.
      ELSE.
        INSERT VALUE #( %cid     = <entity>-%cid
                        OrderKey = row-key ) INTO TABLE mapped-order.
        lcl_sales_order=>remember_change( row-key ).
      ENDIF.
    ENDLOOP.
    lcl_sales_order=>report( EXPORTING messages = messages
                             CHANGING  reported = reported ).
  ENDMETHOD.


  METHOD update.
    DATA changed_fields TYPE zif_bfw_business_object=>field_names.
    DATA rows TYPE lcl_sales_order=>root_rows.
    DATA failed_keys TYPE zif_bfw_business_object=>keys.
    DATA messages TYPE zif_bfw_business_object=>messages.

    " Each instance sends only the fields that its consumer changed
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      CLEAR changed_fields.
      IF <entity>-%control-OrderId = if_abap_behv=>mk-on.
        INSERT `ORDER_ID` INTO TABLE changed_fields.
      ENDIF.
      IF <entity>-%control-CustomerId = if_abap_behv=>mk-on.
        INSERT `CUSTOMER_ID` INTO TABLE changed_fields.
      ENDIF.
      IF <entity>-%control-SalesOrganization = if_abap_behv=>mk-on.
        INSERT `SALES_ORG` INTO TABLE changed_fields.
      ENDIF.
      IF <entity>-%control-Amount = if_abap_behv=>mk-on.
        INSERT `AMOUNT` INTO TABLE changed_fields.
      ENDIF.
      IF <entity>-%control-Currency = if_abap_behv=>mk-on.
        INSERT `AMOUNT_CURR` INTO TABLE changed_fields.
      ENDIF.
      IF changed_fields IS INITIAL.
        CONTINUE.
      ENDIF.

      rows = VALUE #( ( key         = <entity>-OrderKey
                        order_id    = <entity>-OrderId
                        customer_id = <entity>-CustomerId
                        sales_org   = <entity>-SalesOrganization
                        amount      = <entity>-Amount
                        amount_curr = <entity>-Currency ) ).
      lcl_sales_order=>get( )->update( EXPORTING node           = `ROOT`
                                                 rows           = rows
                                                 changed_fields = changed_fields
                                       IMPORTING failed_keys    = failed_keys
                                                 messages       = messages ).
      IF failed_keys IS INITIAL.
        lcl_sales_order=>remember_change( <entity>-OrderKey ).
      ELSE.
        INSERT VALUE #( %tky = <entity>-%tky ) INTO TABLE failed-order.
      ENDIF.
      lcl_sales_order=>report( EXPORTING messages = messages
                               CHANGING  reported = reported ).
    ENDLOOP.
  ENDMETHOD.


  METHOD delete.
    lcl_sales_order=>get( )->delete( EXPORTING node        = `ROOT`
                                               keys        = VALUE #( FOR requested IN keys
                                                                      ( key = requested-OrderKey ) )
                                     IMPORTING failed_keys = DATA(failed_keys)
                                               messages    = DATA(messages) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<deleted>).
      IF line_exists( failed_keys[ key = <deleted>-OrderKey ] ).
        INSERT VALUE #( %tky = <deleted>-%tky ) INTO TABLE failed-order.
      ELSE.
        lcl_sales_order=>remember_change( <deleted>-OrderKey ).
      ENDIF.
    ENDLOOP.
    lcl_sales_order=>report( EXPORTING messages = messages
                             CHANGING  reported = reported ).
  ENDMETHOD.


  METHOD read.
    DATA rows TYPE lcl_sales_order=>root_rows.

    lcl_sales_order=>get( )->read( EXPORTING node        = `ROOT`
                                             keys        = VALUE #( FOR requested IN keys
                                                                    ( key = requested-OrderKey ) )
                                   IMPORTING rows        = rows
                                             failed_keys = DATA(failed_keys) ).

    result = VALUE #( FOR row IN rows ( OrderKey          = row-key
                                        OrderId           = row-order_id
                                        CustomerId        = row-customer_id
                                        SalesOrganization = row-sales_org
                                        Amount            = row-amount
                                        Currency          = row-amount_curr
                                        DeliveryStatus    = row-delivery_status ) ).
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<missing>).
      IF line_exists( failed_keys[ key = <missing>-OrderKey ] ).
        INSERT VALUE #( %tky        = <missing>-%tky
                        %fail-cause = if_abap_behv=>cause-not_found ) INTO TABLE failed-order.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD lock.
    " Reading for update locks the BOPF instances as BOPF itself would on a change
    lcl_sales_order=>get( )->read( EXPORTING node        = `ROOT`
                                             keys        = VALUE #( FOR requested IN keys
                                                                    ( key = requested-OrderKey ) )
                                             for_update  = abap_true
                                   IMPORTING failed_keys = DATA(failed_keys)
                                             messages    = DATA(messages) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<locked>).
      IF line_exists( failed_keys[ key = <locked>-OrderKey ] ).
        INSERT VALUE #( OrderKey    = <locked>-OrderKey
                        %fail-cause = if_abap_behv=>cause-locked ) INTO TABLE failed-order.
      ENDIF.
    ENDLOOP.
    lcl_sales_order=>report( EXPORTING messages = messages
                             CHANGING  reported = reported ).
  ENDMETHOD.
ENDCLASS.


CLASS lsc_zbfw_r_demoorder DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.


CLASS lsc_zbfw_r_demoorder IMPLEMENTATION.

  METHOD finalize.
    zcl_bfw_factory=>get_rap_transaction( )->finalize( IMPORTING rejected = DATA(rejected)
                                                                 messages = DATA(messages) ).
    lcl_sales_order=>report_late( EXPORTING messages = messages
                                  CHANGING  reported = reported ).
    IF rejected = abap_true.
      lcl_sales_order=>fail_refused_save( EXPORTING messages = messages
                                          CHANGING  failed   = failed ).
    ENDIF.
  ENDMETHOD.


  METHOD check_before_save.
    zcl_bfw_factory=>get_rap_transaction( )->check_before_save( IMPORTING rejected = DATA(rejected)
                                                                          messages = DATA(messages) ).
    lcl_sales_order=>report_late( EXPORTING messages = messages
                                  CHANGING  reported = reported ).
    IF rejected = abap_true.
      lcl_sales_order=>fail_refused_save( EXPORTING messages = messages
                                          CHANGING  failed   = failed ).
    ENDIF.
  ENDMETHOD.


  METHOD save.
    lcl_sales_order=>report_late( EXPORTING messages = zcl_bfw_factory=>get_rap_transaction( )->save( )
                                  CHANGING  reported = reported ).
  ENDMETHOD.


  METHOD cleanup.
    zcl_bfw_factory=>get_rap_transaction( )->cleanup( ).
    lcl_sales_order=>forget_changes( ).
  ENDMETHOD.


  METHOD cleanup_finalize.
    zcl_bfw_factory=>get_rap_transaction( )->cleanup_finalize( ).
  ENDMETHOD.
ENDCLASS.
