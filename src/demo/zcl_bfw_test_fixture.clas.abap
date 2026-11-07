CLASS zcl_bfw_test_fixture DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    CONSTANTS customer_id TYPE c LENGTH 30 VALUE 'BFW-FIXTURE-CUSTOMER-1'.
    CONSTANTS first_product_id TYPE c LENGTH 30 VALUE 'BFW-FIXTURE-PRODUCT-1'.
    CONSTANTS second_product_id TYPE c LENGTH 30 VALUE 'BFW-FIXTURE-PRODUCT-2'.
    CONSTANTS first_order_id TYPE c LENGTH 30 VALUE 'BFW-FIXTURE-ORDER-1'.
    CONSTANTS second_order_id TYPE c LENGTH 30 VALUE 'BFW-FIXTURE-ORDER-2'.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES identifier TYPE c LENGTH 30.
    TYPES customers TYPE STANDARD TABLE OF /bobf/s_demo_customer_hdr_k WITH EMPTY KEY.
    TYPES products TYPE STANDARD TABLE OF /bobf/s_demo_product_hdr_k WITH EMPTY KEY.
    TYPES orders TYPE STANDARD TABLE OF /bobf/s_demo_sales_order_hdr_k WITH EMPTY KEY.
    TYPES items TYPE STANDARD TABLE OF /bobf/s_demo_sales_order_itm_k WITH EMPTY KEY.
    TYPES short_texts TYPE STANDARD TABLE OF /bobf/s_demo_short_text_k WITH EMPTY KEY.
    TYPES long_text_roots TYPE STANDARD TABLE OF /bobf/s_demo_longtext_hdr_k WITH EMPTY KEY.
    TYPES long_text_contents TYPE STANDARD TABLE OF /bobf/s_demo_longtext_item_k WITH EMPTY KEY.
    TYPES customer_ids TYPE STANDARD TABLE OF /bobf/s_demo_customer_id WITH EMPTY KEY.
    TYPES product_ids TYPE STANDARD TABLE OF /bobf/s_demo_product_id WITH EMPTY KEY.
    TYPES order_ids TYPE STANDARD TABLE OF /bobf/s_demo_sales_order_id WITH EMPTY KEY.

    TYPES:
      BEGIN OF root_lookup,
        exists        TYPE abap_bool,
        is_successful TYPE abap_bool,
      END OF root_lookup.

    TYPES:
      BEGIN OF long_text_request,
        host_node  TYPE string,
        node       TYPE string,
        parent_key TYPE zif_bfw_business_object=>instance_key,
        content    TYPE string,
      END OF long_text_request.

    CONSTANTS currency TYPE c LENGTH 3 VALUE 'EUR'.
    CONSTANTS sales_org TYPE c LENGTH 4 VALUE 'EMEA'.
    CONSTANTS country TYPE c LENGTH 2 VALUE 'DE'.
    CONSTANTS language TYPE c LENGTH 1 VALUE 'E'.
    CONSTANTS product_type TYPE c LENGTH 8 VALUE 'FIN_PROD'.
    CONSTANTS base_unit TYPE c LENGTH 3 VALUE 'ST'.
    CONSTANTS text_type TYPE c LENGTH 4 VALUE 'MEMO'.

    DATA out TYPE REF TO if_oo_adt_classrun_out.

    METHODS create_master_data
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS create_customer
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS create_product
      IMPORTING
        id            TYPE identifier
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS create_orders
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS create_order
      IMPORTING
        id            TYPE identifier
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS create_long_text
      IMPORTING
        business_object TYPE REF TO zif_bfw_business_object
        request         TYPE long_text_request
      RETURNING
        VALUE(result)   TYPE abap_bool.

    METHODS find_root
      IMPORTING
        business_object TYPE REF TO zif_bfw_business_object
        alternative_key TYPE string
        values          TYPE INDEX TABLE
      RETURNING
        VALUE(result)   TYPE root_lookup.

    METHODS create_rows
      IMPORTING
        business_object TYPE REF TO zif_bfw_business_object
        node            TYPE string
        label           TYPE string OPTIONAL
      EXPORTING
        is_successful   TYPE abap_bool
      CHANGING
        rows            TYPE INDEX TABLE.

    METHODS has_errors
      IMPORTING
        messages      TYPE zif_bfw_business_object=>messages
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS write_messages
      IMPORTING
        messages TYPE zif_bfw_business_object=>messages.
ENDCLASS.



CLASS zcl_bfw_test_fixture IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    me->out = out.
    DATA(transaction) = zcl_bfw_factory=>get_transaction( ).

    TRY.
        IF create_master_data( ) = abap_false.
          transaction->cleanup( ).
          out->write( `Unsaved master data discarded; fixture stopped.` ).
          RETURN.
        ENDIF.
        write_messages( transaction->save( ) ).
        out->write( `Master data saved.` ).

        IF create_orders( ) = abap_false.
          transaction->cleanup( ).
          out->write( `Unsaved orders discarded; fixture stopped.` ).
          RETURN.
        ENDIF.
        write_messages( transaction->save( ) ).
        out->write( `Orders saved.` ).
      CATCH zcx_bfw_access INTO DATA(access_error).
        out->write( access_error->get_text( ) ).
        transaction->cleanup( ).
        out->write( `Unsaved changes discarded; fixture stopped.` ).
      CATCH zcx_bfw_save_rejected INTO DATA(save_error).
        out->write( save_error->get_text( ) ).
        write_messages( save_error->get_messages( ) ).
        transaction->cleanup( ).
        out->write( `Unsaved changes discarded; fixture stopped.` ).
    ENDTRY.
  ENDMETHOD.


  METHOD create_master_data.
    IF create_customer( ) = abap_false.
      RETURN.
    ENDIF.
    IF create_product( first_product_id ) = abap_false.
      RETURN.
    ENDIF.
    result = create_product( second_product_id ).
  ENDMETHOD.


  METHOD create_customer.
    DATA(business_object) = zcl_bfw_factory=>get_business_object( `/BOBF/DEMO_CUSTOMER` ).
    DATA(lookup) = find_root(
        business_object = business_object
        alternative_key = `CUSTOMER_ID`
        values          = VALUE customer_ids( ( customer_id = customer_id ) ) ).
    IF lookup-is_successful = abap_false.
      RETURN.
    ENDIF.
    IF lookup-exists = abap_true.
      out->write( |Customer { customer_id }: skipped| ).
      result = abap_true.
      RETURN.
    ENDIF.

    " SAP's customer structure spells the country component ADDRESS_CONTRY.
    DATA(customers) = VALUE customers(
        ( customer_id    = customer_id
          sales_org      = sales_org
          cust_curr      = currency
          address_contry = country
          address        = `BFW fixture customer, Berlin, Germany` ) ).
    create_rows( EXPORTING business_object = business_object
                           node            = `ROOT`
                           label           = |Customer { customer_id }|
                 IMPORTING is_successful   = result
                 CHANGING  rows            = customers ).
  ENDMETHOD.


  METHOD create_product.
    DATA(business_object) = zcl_bfw_factory=>get_business_object( `/BOBF/DEMO_PRODUCT` ).
    DATA(lookup) = find_root(
        business_object = business_object
        alternative_key = `PRODUCT_ID`
        values          = VALUE product_ids( ( product_id = id ) ) ).
    IF lookup-is_successful = abap_false.
      RETURN.
    ENDIF.
    IF lookup-exists = abap_true.
      out->write( |Product { id }: skipped| ).
      result = abap_true.
      RETURN.
    ENDIF.

    DATA(products) = VALUE products(
        ( product_id      = id
          product_type    = product_type
          base_uom        = base_unit
          sell_price      = 25
          sell_price_curr = currency
          buy_price       = 10
          buy_price_curr  = currency ) ).
    create_rows( EXPORTING business_object = business_object
                           node            = `ROOT`
                           label           = |Product { id }|
                 IMPORTING is_successful   = result
                 CHANGING  rows            = products ).
  ENDMETHOD.


  METHOD create_orders.
    IF create_order( first_order_id ) = abap_false.
      RETURN.
    ENDIF.
    result = create_order( second_order_id ).
  ENDMETHOD.


  METHOD create_order.
    DATA(business_object) = zcl_bfw_factory=>get_business_object( `/BOBF/DEMO_SALES_ORDER` ).
    DATA(lookup) = find_root(
        business_object = business_object
        alternative_key = `ORDER_ID`
        values          = VALUE order_ids( ( order_id = id ) ) ).
    IF lookup-is_successful = abap_false.
      RETURN.
    ENDIF.
    IF lookup-exists = abap_true.
      out->write( |Order { id }: skipped| ).
      result = abap_true.
      RETURN.
    ENDIF.

    DATA(orders) = VALUE orders(
        ( order_id    = id
          customer_id = customer_id
          sales_org   = sales_org
          amount_curr = currency ) ).
    create_rows( EXPORTING business_object = business_object
                           node            = `ROOT`
                           label           = |Order { id }|
                 IMPORTING is_successful   = DATA(is_created)
                 CHANGING  rows            = orders ).
    IF is_created = abap_false.
      RETURN.
    ENDIF.

    DATA(root_key) = orders[ 1 ]-key.
    DATA(items) = VALUE items(
        ( parent_key  = root_key
          item_no     = 10
          product_id  = first_product_id
          amount      = 25
          amount_curr = currency )
        ( parent_key  = root_key
          item_no     = 20
          product_id  = second_product_id
          amount      = 25
          amount_curr = currency ) ).
    create_rows( EXPORTING business_object = business_object
                           node            = `ITEM`
                 IMPORTING is_successful   = is_created
                 CHANGING  rows            = items ).
    IF is_created = abap_false.
      RETURN.
    ENDIF.

    DATA(short_texts) = VALUE short_texts(
        ( parent_key = root_key
          language   = language
          text       = |Fixture order { id }| ) ).
    create_rows( EXPORTING business_object = business_object
                           node            = `ROOT_TEXT`
                 IMPORTING is_successful   = is_created
                 CHANGING  rows            = short_texts ).
    IF is_created = abap_false.
      RETURN.
    ENDIF.

    IF create_long_text(
           business_object = business_object
           request         = VALUE #( host_node  = `ROOT`
                                      node       = `ROOT_LONG_TEXT`
                                      parent_key = root_key
                                      content    = |Root memo for fixture order { id }.| ) ) = abap_false.
      RETURN.
    ENDIF.
    result = create_long_text(
        business_object = business_object
        request         = VALUE #( host_node  = `ITEM`
                                   node       = `ITEM_LONG_TEXT`
                                   parent_key = items[ 1 ]-key
                                   content    = |First item memo for fixture order { id }.| ) ).
  ENDMETHOD.


  METHOD create_long_text.
    DATA long_text_roots TYPE long_text_roots.
    DATA is_created TYPE abap_bool.

    " The business object may create the root of the dependent object itself, e.g. in a determination
    business_object->read_by_association(
        EXPORTING node        = request-host_node
                  association = request-node
                  keys        = VALUE #( ( key = request-parent_key ) )
        IMPORTING links       = DATA(links)
                  messages    = DATA(messages) ).
    write_messages( messages ).
    IF has_errors( messages ) = abap_true.
      RETURN.
    ENDIF.

    DATA(long_text_root_key) = VALUE zif_bfw_business_object=>instance_key( links[ 1 ]-target_key OPTIONAL ).
    IF long_text_root_key IS INITIAL.
      long_text_roots = VALUE #( ( parent_key = request-parent_key ) ).
      create_rows( EXPORTING business_object = business_object
                             node            = request-node
                   IMPORTING is_successful   = is_created
                   CHANGING  rows            = long_text_roots ).
      IF is_created = abap_false.
        RETURN.
      ENDIF.
      long_text_root_key = long_text_roots[ 1 ]-key.
    ENDIF.

    DATA(long_text_contents) = VALUE long_text_contents(
        ( parent_key   = long_text_root_key
          language     = language
          text_type    = text_type
          text_content = request-content ) ).
    create_rows( EXPORTING business_object = business_object
                           node            = |{ request-node }.CONTENT|
                 IMPORTING is_successful   = result
                 CHANGING  rows            = long_text_contents ).
  ENDMETHOD.


  METHOD find_root.
    business_object->convert_alternative_key(
        EXPORTING node            = `ROOT`
                  alternative_key = alternative_key
                  values          = values
        IMPORTING keys            = DATA(keys)
                  messages        = DATA(messages) ).
    write_messages( messages ).
    result = VALUE #( exists        = xsdbool( keys IS NOT INITIAL )
                      is_successful = xsdbool( has_errors( messages ) = abap_false ) ).
  ENDMETHOD.


  METHOD create_rows.
    DATA failed_key TYPE REF TO zif_bfw_business_object=>key_entry.

    business_object->create(
        EXPORTING node        = node
        IMPORTING failed_keys = DATA(failed_keys)
                  messages    = DATA(messages)
        CHANGING  rows        = rows ).
    is_successful = xsdbool( failed_keys IS INITIAL AND has_errors( messages ) = abap_false ).
    IF label IS NOT INITIAL.
      IF is_successful = abap_true.
        out->write( |{ label }: created (pending save)| ).
      ELSE.
        out->write( |{ label }: creation failed| ).
      ENDIF.
    ENDIF.
    write_messages( messages ).
    LOOP AT failed_keys REFERENCE INTO failed_key.
      out->write( |Create { node }: failed key { failed_key->key }| ).
    ENDLOOP.
  ENDMETHOD.


  METHOD has_errors.
    result = xsdbool( line_exists( messages[ severity = 'E' ] )
                     OR line_exists( messages[ severity = 'A' ] )
                     OR line_exists( messages[ severity = 'X' ] ) ).
  ENDMETHOD.


  METHOD write_messages.
    DATA message TYPE REF TO zif_bfw_business_object=>message.

    LOOP AT messages REFERENCE INTO message.
      out->write( message->* ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
