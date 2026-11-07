"! Runs the RAP demo sales order ZBFW_R_DEMOORDER with EML (F9 in ADT): create, update, a create with a consistency
"! error, and delete, each committed by RAP. BOPF saves in the RAP save sequence through ZIF_BFW_RAP_TRANSACTION.
"! The demo sales order has no consistency group, so BOPF saves an order with a consistency error and only reports
"! the error. Writes to the database and deletes its own orders at the end; needs the customer of
"! ZCL_BFW_TEST_FIXTURE.
CLASS zcl_bfw_rap_demo_run DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES order_key TYPE zbfw_r_demoorder-OrderKey.
    TYPES order_keys TYPE STANDARD TABLE OF order_key WITH EMPTY KEY.
    TYPES messages TYPE STANDARD TABLE OF REF TO if_abap_behv_message WITH EMPTY KEY.

    CONSTANTS order_id TYPE zbfw_r_demoorder-OrderId VALUE 'BFW-RAP-DEMO-ORDER'.
    CONSTANTS error_order_id TYPE zbfw_r_demoorder-OrderId VALUE 'BFW-RAP-DEMO-ERROR'.
    "! Order IDs of all orders of this run
    CONSTANTS order_id_pattern TYPE string VALUE `BFW-RAP-DEMO-%`.
    CONSTANTS customer_id TYPE zbfw_r_demoorder-CustomerId VALUE 'BFW-FIXTURE-CUSTOMER-1'.
    CONSTANTS unknown_customer_id TYPE zbfw_r_demoorder-CustomerId VALUE 'BFW-NO-SUCH-CUSTOMER'.
    CONSTANTS sales_org TYPE zbfw_r_demoorder-SalesOrganization VALUE 'EMEA'.
    CONSTANTS currency TYPE zbfw_r_demoorder-Currency VALUE 'EUR'.

    DATA out TYPE REF TO if_oo_adt_classrun_out.

    "! Deletes orders of earlier runs, so that the run can be repeated
    METHODS delete_leftovers.

    METHODS create_order
      RETURNING
        VALUE(result) TYPE order_key.

    METHODS update_amount
      IMPORTING
        key TYPE order_key.

    METHODS create_order_with_error
      RETURNING
        VALUE(result) TYPE order_key.

    METHODS delete_orders
      IMPORTING
        keys TYPE order_keys.

    "! Line with the order as the database holds it after the commit
    METHODS write_saved_order
      IMPORTING
        key TYPE order_key.

    METHODS write_messages
      IMPORTING
        messages TYPE messages.
ENDCLASS.



CLASS zcl_bfw_rap_demo_run IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    me->out = out.
    delete_leftovers( ).

    DATA(key) = create_order( ).
    IF key IS INITIAL.
      RETURN.
    ENDIF.
    update_amount( key ).
    DATA(error_key) = create_order_with_error( ).
    delete_orders( VALUE #( ( key ) ( error_key ) ) ).
  ENDMETHOD.


  METHOD delete_leftovers.
    SELECT OrderKey FROM zbfw_r_demoorder
      WHERE OrderId LIKE @order_id_pattern
      ORDER BY OrderKey
      INTO TABLE @DATA(leftovers).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zbfw_r_demoorder
      ENTITY Order
        DELETE FROM VALUE #( FOR leftover IN leftovers ( OrderKey = leftover-OrderKey ) ).
    COMMIT ENTITIES.
    out->write( |Leftovers of an earlier run deleted: { lines( leftovers ) }| ).
  ENDMETHOD.


  METHOD create_order.
    MODIFY ENTITIES OF zbfw_r_demoorder
      ENTITY Order
        CREATE FIELDS ( OrderId CustomerId SalesOrganization Amount Currency )
        WITH VALUE #( ( %cid              = 'ORDER'
                        OrderId           = order_id
                        CustomerId        = customer_id
                        SalesOrganization = sales_org
                        Amount            = 100
                        Currency          = currency ) )
      MAPPED DATA(mapped)
      FAILED DATA(failed)
      REPORTED DATA(reported).
    COMMIT ENTITIES RESPONSE OF zbfw_r_demoorder
      FAILED DATA(commit_failed)
      REPORTED DATA(commit_reported).

    out->write( |1. Create: { COND #( WHEN failed IS INITIAL AND commit_failed IS INITIAL
                                     THEN `saved` ELSE `FAILED` ) }| ).
    write_messages( VALUE #( ( LINES OF VALUE messages( FOR entry IN reported-order ( entry-%msg ) ) )
                             ( LINES OF reported-%other )
                             ( LINES OF VALUE messages( FOR late_entry IN commit_reported-order ( late_entry-%msg ) ) )
                             ( LINES OF commit_reported-%other ) ) ).
    IF failed IS NOT INITIAL OR commit_failed IS NOT INITIAL OR mapped-order IS INITIAL.
      RETURN.
    ENDIF.
    result = mapped-order[ 1 ]-OrderKey.
    write_saved_order( result ).
  ENDMETHOD.


  METHOD update_amount.
    MODIFY ENTITIES OF zbfw_r_demoorder
      ENTITY Order
        UPDATE FIELDS ( Amount )
        WITH VALUE #( ( OrderKey = key
                        Amount   = 250 ) )
      FAILED DATA(failed)
      REPORTED DATA(reported).
    COMMIT ENTITIES RESPONSE OF zbfw_r_demoorder
      FAILED DATA(commit_failed)
      REPORTED DATA(commit_reported).

    out->write( |2. Update amount to 250: { COND #( WHEN failed IS INITIAL AND commit_failed IS INITIAL
                                                   THEN `saved` ELSE `FAILED` ) }| ).
    write_messages( VALUE #( ( LINES OF VALUE messages( FOR entry IN reported-order ( entry-%msg ) ) )
                             ( LINES OF reported-%other )
                             ( LINES OF VALUE messages( FOR late_entry IN commit_reported-order ( late_entry-%msg ) ) )
                             ( LINES OF commit_reported-%other ) ) ).
    write_saved_order( key ).
  ENDMETHOD.


  METHOD create_order_with_error.
    " The BOPF validation CHECK_ROOT reports the unknown customer, but without a consistency group BOPF saves anyway
    MODIFY ENTITIES OF zbfw_r_demoorder
      ENTITY Order
        CREATE FIELDS ( OrderId CustomerId SalesOrganization Amount Currency )
        WITH VALUE #( ( %cid              = 'ERROR'
                        OrderId           = error_order_id
                        CustomerId        = unknown_customer_id
                        SalesOrganization = sales_org
                        Amount            = 10
                        Currency          = currency ) )
      MAPPED DATA(mapped)
      FAILED DATA(failed)
      REPORTED DATA(reported).
    COMMIT ENTITIES RESPONSE OF zbfw_r_demoorder
      FAILED DATA(commit_failed)
      REPORTED DATA(commit_reported).

    out->write( |3. Create with an unknown customer: { COND #( WHEN failed IS INITIAL AND commit_failed IS INITIAL
                                                              THEN `saved with the error message of BOPF`
                                                              ELSE `FAILED` ) }| ).
    write_messages( VALUE #( ( LINES OF VALUE messages( FOR entry IN reported-order ( entry-%msg ) ) )
                             ( LINES OF reported-%other )
                             ( LINES OF VALUE messages( FOR late_entry IN commit_reported-order ( late_entry-%msg ) ) )
                             ( LINES OF commit_reported-%other ) ) ).
    IF mapped-order IS INITIAL.
      RETURN.
    ENDIF.
    result = mapped-order[ 1 ]-OrderKey.
    write_saved_order( result ).
  ENDMETHOD.


  METHOD delete_orders.
    MODIFY ENTITIES OF zbfw_r_demoorder
      ENTITY Order
        DELETE FROM VALUE #( FOR key IN keys WHERE ( table_line IS NOT INITIAL ) ( OrderKey = key ) )
      FAILED DATA(failed)
      REPORTED DATA(reported).
    COMMIT ENTITIES RESPONSE OF zbfw_r_demoorder
      FAILED DATA(commit_failed)
      REPORTED DATA(commit_reported).

    SELECT COUNT(*) FROM zbfw_r_demoorder WHERE OrderId LIKE @order_id_pattern INTO @DATA(remaining_count).
    out->write( |4. Delete both orders: { COND #( WHEN failed IS INITIAL AND commit_failed IS INITIAL
                                                 THEN `saved` ELSE `FAILED` ) }, orders left in the database: {
                                                 remaining_count }| ).
    write_messages( VALUE #( ( LINES OF VALUE messages( FOR entry IN reported-order ( entry-%msg ) ) )
                             ( LINES OF reported-%other )
                             ( LINES OF VALUE messages( FOR late_entry IN commit_reported-order ( late_entry-%msg ) ) )
                             ( LINES OF commit_reported-%other ) ) ).
  ENDMETHOD.


  METHOD write_saved_order.
    SELECT SINGLE OrderId, CustomerId, SalesOrganization, Amount, Currency
      FROM zbfw_r_demoorder
      WHERE OrderKey = @key
      INTO @DATA(saved_order).
    IF sy-subrc <> 0.
      out->write( `   not in the database` ).
      RETURN.
    ENDIF.
    out->write( |   database: { saved_order-OrderId } / { saved_order-CustomerId } / { saved_order-SalesOrganization } / {
                saved_order-Amount } { saved_order-Currency }| ).
  ENDMETHOD.


  METHOD write_messages.
    LOOP AT messages ASSIGNING FIELD-SYMBOL(<message>) WHERE table_line IS BOUND.
      out->write( |   message: { <message>->if_message~get_text( ) }| ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
