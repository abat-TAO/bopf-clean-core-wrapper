CLASS ltcl_sales_order_integration DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF root_projection,
        key       TYPE zif_bfw_business_object=>instance_key,
        order_id  TYPE /bobf/s_demo_sales_order_hdr_k-order_id,
        sales_org TYPE /bobf/s_demo_sales_order_hdr_k-sales_org,
      END OF root_projection,
      root_projections TYPE STANDARD TABLE OF root_projection WITH EMPTY KEY.

    TYPES:
      BEGIN OF item_change,
        key    TYPE zif_bfw_business_object=>instance_key,
        amount TYPE /bobf/s_demo_sales_order_itm_k-amount,
      END OF item_change,
      item_changes TYPE STANDARD TABLE OF item_change WITH EMPTY KEY.

    TYPES:
      BEGIN OF short_text_projection,
        key        TYPE zif_bfw_business_object=>instance_key,
        parent_key TYPE zif_bfw_business_object=>instance_key,
        language   TYPE /bobf/s_demo_short_text_k-language,
        text       TYPE /bobf/s_demo_short_text_k-text,
      END OF short_text_projection,
      short_text_projections TYPE STANDARD TABLE OF short_text_projection WITH EMPTY KEY.

    TYPES order_ids TYPE STANDARD TABLE OF /bobf/s_demo_sales_order_id WITH EMPTY KEY.
    TYPES items TYPE STANDARD TABLE OF /bobf/s_demo_sales_order_itm_k WITH EMPTY KEY.
    TYPES customers TYPE STANDARD TABLE OF /bobf/s_demo_customer_hdr_k WITH EMPTY KEY.
    TYPES short_texts TYPE STANDARD TABLE OF /bobf/s_demo_short_text_k WITH EMPTY KEY.
    TYPES long_text_roots TYPE STANDARD TABLE OF /bobf/s_demo_longtext_hdr_k WITH EMPTY KEY.
    TYPES long_text_contents TYPE STANDARD TABLE OF /bobf/s_demo_longtext_item_k WITH EMPTY KEY.

    DATA sales_order TYPE REF TO zif_bfw_business_object.
    DATA first_order_key TYPE zif_bfw_business_object=>instance_key.
    DATA second_order_key TYPE zif_bfw_business_object=>instance_key.
    DATA order_keys TYPE zif_bfw_business_object=>keys.

    METHODS setup.
    METHODS teardown.
    METHODS get_fixture_order_key
      IMPORTING
        order_id      TYPE /bobf/s_demo_sales_order_id-order_id
      RETURNING
        VALUE(result) TYPE zif_bfw_business_object=>instance_key.
    METHODS read_first_order_items
      RETURNING
        VALUE(result) TYPE items.
    METHODS read_long_text_root_key
      RETURNING
        VALUE(result) TYPE zif_bfw_business_object=>instance_key.
    METHODS create_buffered_root_texts
      RETURNING
        VALUE(result) TYPE short_texts.
    METHODS get_fixture_selection
      RETURNING
        VALUE(result) TYPE zif_bfw_business_object=>selection_parameters.
    METHODS assert_no_errors
      IMPORTING
        messages TYPE zif_bfw_business_object=>messages.

    METHODS read_maps_root_projection FOR TESTING.
    METHODS read_reference_has_node_type FOR TESTING.
    METHODS read_for_update_locks_root FOR TESTING.
    METHODS item_association_links_rows FOR TESTING.
    METHODS long_text_has_fixture_content FOR TESTING.
    METHODS cross_bo_returns_customer FOR TESTING.
    METHODS alt_key_keeps_input_index FOR TESTING.
    METHODS select_all_contains_orders FOR TESTING.
    METHODS select_by_elements_finds_order FOR TESTING.
    METHODS query_sorts_keys_and_rows FOR TESTING.
    METHODS query_filters_fixture_keys FOR TESTING.
    METHODS query_pages_sorted_orders FOR TESTING.
    METHODS root_text_filter_limits_rows FOR TESTING.
    METHODS root_text_no_filter_keeps_rows FOR TESTING.
    METHODS facade_text_filter_limits_rows FOR TESTING.
    METHODS facade_text_no_filter_keeps FOR TESTING.
    METHODS facade_path_reads_products FOR TESTING.
    METHODS unknown_node_raises_access FOR TESTING.
    METHODS update_changes_item_amount FOR TESTING.
    METHODS create_adds_root_text FOR TESTING.
    METHODS create_adds_long_text_content FOR TESTING.
    METHODS delete_makes_item_unreadable FOR TESTING.
    METHODS deliver_marks_requested_item FOR TESTING.
    METHODS archive_marks_order FOR TESTING.
ENDCLASS.



CLASS ltcl_sales_order_integration IMPLEMENTATION.

  METHOD setup.
    " Given the saved fixture orders; each test gets fresh keys after the previous cleanup
    sales_order = zcl_bfw_factory=>get_business_object( `/BOBF/DEMO_SALES_ORDER` ).
    first_order_key = get_fixture_order_key( zcl_bfw_test_fixture=>first_order_id ).
    second_order_key = get_fixture_order_key( zcl_bfw_test_fixture=>second_order_id ).
    order_keys = VALUE #( ( key = first_order_key ) ( key = second_order_key ) ).
  ENDMETHOD.


  METHOD teardown.
    zcl_bfw_factory=>get_transaction( )->cleanup( ).
  ENDMETHOD.


  METHOD get_fixture_order_key.
    sales_order->convert_alternative_key(
        EXPORTING node            = `ROOT`
                  alternative_key = `ORDER_ID`
                  values          = VALUE order_ids( ( order_id = order_id ) )
        IMPORTING keys            = DATA(keys)
                  messages        = DATA(messages) ).
    assert_no_errors( messages ).
    IF keys IS INITIAL.
      cl_abap_unit_assert=>skip( `run ZCL_BFW_TEST_FIXTURE first` ).
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = lines( keys )
                                        exp = 1 ).
    result = keys[ 1 ]-key.
    cl_abap_unit_assert=>assert_not_initial( act = result ).
  ENDMETHOD.


  METHOD read_first_order_items.
    sales_order->read_by_association(
        EXPORTING node        = `ROOT`
                  association = `ITEM`
                  keys        = VALUE #( ( key = first_order_key ) )
        IMPORTING rows        = result
                  failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = lines( result )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( result[ item_no = 10 ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( result[ item_no = 20 ] ) ) ).
  ENDMETHOD.


  METHOD read_long_text_root_key.
    DATA roots TYPE long_text_roots.

    sales_order->read_by_association(
        EXPORTING node        = `ROOT`
                  association = `ROOT_LONG_TEXT`
                  keys        = VALUE #( ( key = first_order_key ) )
        IMPORTING links       = DATA(links)
                  rows        = roots
                  failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = lines( roots )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_not_initial( act = roots[ 1 ]-key ).
    result = roots[ 1 ]-key.
    cl_abap_unit_assert=>assert_equals(
        act = links
        exp = VALUE zif_bfw_business_object=>key_links( ( source_key = first_order_key target_key = result ) ) ).
  ENDMETHOD.


  METHOD assert_no_errors.
    DATA message TYPE REF TO zif_bfw_business_object=>message.

    LOOP AT messages REFERENCE INTO message
         WHERE severity = 'E' OR severity = 'A' OR severity = 'X'.
      cl_abap_unit_assert=>fail(
          |{ message->severity }: { message->bapi_return-id }-{ message->bapi_return-number } { message->bapi_return-message }| ).
    ENDLOOP.
  ENDMETHOD.


  METHOD create_buffered_root_texts.
    DATA existing_texts TYPE short_texts.

    " Replace saved texts only in the buffer so each test has exactly two languages
    sales_order->read_by_association(
        EXPORTING node        = `ROOT`
                  association = `ROOT_TEXT`
                  keys        = VALUE #( ( key = first_order_key ) )
        IMPORTING rows        = existing_texts
                  failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    sales_order->delete(
        EXPORTING node        = `ROOT_TEXT`
                  keys        = CORRESPONDING #( existing_texts )
        IMPORTING failed_keys = failed_keys
                  messages    = messages ).
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).

    result = VALUE #( ( parent_key = first_order_key
                        language   = 'D'
                        text       = 'Buffered German filter text' )
                      ( parent_key = first_order_key
                        language   = 'F'
                        text       = 'Buffered French filter text' ) ).
    sales_order->create(
        EXPORTING node        = `ROOT_TEXT`
        IMPORTING failed_keys = failed_keys
                  messages    = messages
        CHANGING  rows        = result ).
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_not_initial( result[ 1 ]-key ).
    cl_abap_unit_assert=>assert_not_initial( result[ 2 ]-key ).
  ENDMETHOD.


  METHOD get_fixture_selection.
    result = VALUE #( ( attribute_name = `ORDER_ID`
                        sign           = 'I'
                        option         = 'EQ'
                        low            = zcl_bfw_test_fixture=>first_order_id )
                      ( attribute_name = `ORDER_ID`
                        sign           = 'I'
                        option         = 'EQ'
                        low            = zcl_bfw_test_fixture=>second_order_id ) ).
  ENDMETHOD.


  METHOD read_maps_root_projection.
    DATA orders TYPE root_projections.

    " When reading only the caller's selected root fields
    sales_order->read(
        EXPORTING node        = `ROOT`
                  keys        = order_keys
        IMPORTING rows        = orders
                  failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).

    " Then mapping by name preserves both identities and the fixture sales organization
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    SORT orders BY order_id.
    cl_abap_unit_assert=>assert_equals(
        act = orders
        exp = VALUE root_projections( ( key       = first_order_key
                                        order_id  = zcl_bfw_test_fixture=>first_order_id
                                        sales_org = 'EMEA' )
                                      ( key       = second_order_key
                                        order_id  = zcl_bfw_test_fixture=>second_order_id
                                        sales_org = 'EMEA' ) ) ).
  ENDMETHOD.


  METHOD read_reference_has_node_type.
    " When requesting a reference instead of a projection
    DATA(result) = sales_order->read_reference( node = `ROOT`
                                                keys = order_keys ).

    " Then the reference can be cast to the configured node table type
    cl_abap_unit_assert=>assert_bound( act = result ).
    DATA(orders_reference) = CAST /bobf/t_demo_sales_order_hdr_k( result ).
    DATA(orders) = orders_reference->*.
    cl_abap_unit_assert=>assert_equals( act = lines( orders )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = orders[ KEY key_sort COMPONENTS key = first_order_key ]-order_id
                                        exp = zcl_bfw_test_fixture=>first_order_id ).
    cl_abap_unit_assert=>assert_equals( act = orders[ KEY key_sort COMPONENTS key = second_order_key ]-order_id
                                        exp = zcl_bfw_test_fixture=>second_order_id ).
  ENDMETHOD.


  METHOD read_for_update_locks_root.
    DATA orders TYPE root_projections.

    " When acquiring exclusive locks in a single session
    sales_order->read(
        EXPORTING node        = `ROOT`
                  keys        = order_keys
                  for_update  = abap_true
        IMPORTING rows        = orders
                  failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).

    " Then both requested roots remain readable without failed locks
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = lines( orders )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( orders[ key = first_order_key ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( orders[ key = second_order_key ] ) ) ).
  ENDMETHOD.


  METHOD item_association_links_rows.
    DATA order_items TYPE items.
    DATA order_key TYPE REF TO zif_bfw_business_object=>key_entry.
    DATA item TYPE REF TO /bobf/s_demo_sales_order_itm_k.

    " When following the composition for both fixture orders
    sales_order->read_by_association(
        EXPORTING node        = `ROOT`
                  association = `ITEM`
                  keys        = order_keys
        IMPORTING links       = DATA(links)
                  rows        = order_items
                  failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).

    " Then every order has items 10 and 20, and every row has its source-to-target link
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = lines( order_items )
                                        exp = 4 ).
    cl_abap_unit_assert=>assert_equals( act = lines( links )
                                        exp = 4 ).
    LOOP AT order_keys REFERENCE INTO order_key.
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( line_exists( order_items[ parent_key = order_key->key item_no = 10 ] ) ) ).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( line_exists( order_items[ parent_key = order_key->key item_no = 20 ] ) ) ).
    ENDLOOP.
    LOOP AT order_items REFERENCE INTO item.
      cl_abap_unit_assert=>assert_not_initial( act = item->key ).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( line_exists( links[ source_key = item->parent_key target_key = item->key ] ) ) ).
    ENDLOOP.
  ENDMETHOD.


  METHOD long_text_has_fixture_content.
    DATA contents TYPE long_text_contents.
    DATA(long_text_root_key) = read_long_text_root_key( ).

    " When traversing from the delegated root to its qualified CONTENT node
    sales_order->read_by_association(
        EXPORTING node        = `ROOT_LONG_TEXT`
                  association = `CONTENT`
                  keys        = VALUE #( ( key = long_text_root_key ) )
        IMPORTING links       = DATA(links)
                  rows        = contents
                  failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).

    " Then the dependent object returns the saved fixture memo
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = lines( contents )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
        act = links
        exp = VALUE zif_bfw_business_object=>key_links(
            ( source_key = long_text_root_key target_key = contents[ 1 ]-key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = contents[ 1 ]-parent_key
                                        exp = long_text_root_key ).
    cl_abap_unit_assert=>assert_equals(
        act = contents[ 1 ]-text_content
        exp = |Root memo for fixture order { zcl_bfw_test_fixture=>first_order_id }.| ).
  ENDMETHOD.


  METHOD cross_bo_returns_customer.
    DATA customer_roots TYPE customers.

    " When following a cross-BO association from the sales order
    sales_order->read_by_association(
        EXPORTING node        = `ROOT`
                  association = `CUSTOMER_ROOT`
                  keys        = VALUE #( ( key = first_order_key ) )
        IMPORTING links       = DATA(links)
                  rows        = customer_roots
                  failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).

    " Then rows use the customer node's structure and identify the fixture customer
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = lines( customer_roots )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = customer_roots[ 1 ]-customer_id
                                        exp = zcl_bfw_test_fixture=>customer_id ).
    cl_abap_unit_assert=>assert_not_initial( act = customer_roots[ 1 ]-key ).
    cl_abap_unit_assert=>assert_equals(
        act = links
        exp = VALUE zif_bfw_business_object=>key_links(
            ( source_key = first_order_key target_key = customer_roots[ 1 ]-key ) ) ).
  ENDMETHOD.


  METHOD alt_key_keeps_input_index.
    " Given a missing value before the existing value, successful indexes must not be renumbered
    DATA(values) = VALUE order_ids( ( order_id = 'BFW-MISSING-ORDER' )
                                   ( order_id = zcl_bfw_test_fixture=>first_order_id ) ).

    " When converting both alternative-key values together
    sales_order->convert_alternative_key(
        EXPORTING node            = `ROOT`
                  alternative_key = `ORDER_ID`
                  values          = values
        IMPORTING keys            = DATA(keys)
                  key_indexes     = DATA(key_indexes)
                  messages        = DATA(messages) ).

    " Then only the existing value contributes a key, at its original input index
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_equals( act = keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = first_order_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = key_indexes
        exp = VALUE zif_bfw_business_object=>key_indexes( ( index = 2 key = first_order_key ) ) ).
  ENDMETHOD.


  METHOD select_all_contains_orders.
    " When querying all roots, other saved orders are allowed to exist
    sales_order->query(
        EXPORTING node     = `ROOT`
                  query    = `SELECT_ALL`
        IMPORTING keys     = DATA(keys)
                  messages = DATA(messages) ).

    " Then the result includes both fixture orders
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( keys[ key = first_order_key ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( keys[ key = second_order_key ] ) ) ).
  ENDMETHOD.


  METHOD select_by_elements_finds_order.
    " When filtering by the first fixture order's external ID
    sales_order->query(
        EXPORTING node                 = `ROOT`
                  query                = `SELECT_BY_ELEMENTS`
                  selection_parameters = VALUE #( ( attribute_name = `ORDER_ID`
                                                    sign           = 'I'
                                                    option         = 'EQ'
                                                    low            = zcl_bfw_test_fixture=>first_order_id ) )
        IMPORTING keys                 = DATA(keys)
                  messages             = DATA(messages) ).

    " Then exactly that order key is returned
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_equals( act = keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = first_order_key ) ) ).
  ENDMETHOD.


  METHOD query_sorts_keys_and_rows.
    DATA orders TYPE root_projections.

    " Given only the two saved fixture order IDs
    DATA(selection_parameters) = get_fixture_selection( ).

    " When sorting the restricted query by descending order ID
    sales_order->query(
        EXPORTING node                 = `ROOT`
                  query                = `SELECT_BY_ELEMENTS`
                  selection_parameters = selection_parameters
                  sorting              = VALUE #( ( attribute_name = `order_id` descending = abap_true ) )
        IMPORTING keys                 = DATA(keys)
                  rows                 = orders
                  messages             = DATA(messages) ).

    " Then keys and rows retain the requested order without sorting the result in the test
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_equals(
        act = keys
        exp = VALUE zif_bfw_business_object=>keys( ( key = second_order_key ) ( key = first_order_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = orders
        exp = VALUE root_projections( ( key       = second_order_key
                                        order_id  = zcl_bfw_test_fixture=>second_order_id
                                        sales_org = 'EMEA' )
                                      ( key       = first_order_key
                                        order_id  = zcl_bfw_test_fixture=>first_order_id
                                        sales_org = 'EMEA' ) ) ).
  ENDMETHOD.


  METHOD query_filters_fixture_keys.
    DATA orders TYPE root_projections.

    " Given both fixture IDs and a key restriction to the first order
    DATA(selection_parameters) = get_fixture_selection( ).

    " When applying the key restriction together with the descending sort
    sales_order->query(
        EXPORTING node                 = `ROOT`
                  query                = `SELECT_BY_ELEMENTS`
                  selection_parameters = selection_parameters
                  filter_keys          = VALUE #( ( key = first_order_key ) )
                  sorting              = VALUE #( ( attribute_name = `ORDER_ID` descending = abap_true ) )
        IMPORTING keys                 = DATA(keys)
                  rows                 = orders
                  messages             = DATA(messages) ).

    " Then the second fixture order is excluded from both result tables
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_equals(
        act = keys
        exp = VALUE zif_bfw_business_object=>keys( ( key = first_order_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = orders
        exp = VALUE root_projections( ( key       = first_order_key
                                        order_id  = zcl_bfw_test_fixture=>first_order_id
                                        sales_org = 'EMEA' ) ) ).
  ENDMETHOD.


  METHOD query_pages_sorted_orders.
    DATA orders TYPE root_projections.

    " Given both saved fixture IDs with the second order sorting first
    DATA(selection_parameters) = get_fixture_selection( ).

    " When requesting one row starting at the second position
    sales_order->query(
        EXPORTING node                 = `ROOT`
                  query                = `SELECT_BY_ELEMENTS`
                  selection_parameters = selection_parameters
                  maximum_rows         = 1
                  sorting              = VALUE #( ( attribute_name = `ORDER_ID` descending = abap_true ) )
                  paging               = VALUE #( start_row = 2 )
        IMPORTING keys                 = DATA(keys)
                  rows                 = orders
                  messages             = DATA(messages) ).

    " Then the page contains only the first fixture order, second in the requested sort
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_equals(
        act = keys
        exp = VALUE zif_bfw_business_object=>keys( ( key = first_order_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = orders
        exp = VALUE root_projections( ( key       = first_order_key
                                        order_id  = zcl_bfw_test_fixture=>first_order_id
                                        sales_org = 'EMEA' ) ) ).
  ENDMETHOD.


  METHOD root_text_filter_limits_rows.
    DATA texts TYPE short_texts.

    " Given German and French texts created in the first order's buffer
    DATA(new_texts) = create_buffered_root_texts( ).

    " When following the parameterized association with a German language filter
    sales_order->read_by_association(
        EXPORTING node        = `ROOT`
                  association = `ROOT_TEXT`
                  keys        = VALUE #( ( key = first_order_key ) )
                  filter      = VALUE /bobf/s_demo_language_code( language = 'D' )
        IMPORTING rows        = texts
                  failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).

    " Then only the newly created German text is returned
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals(
        act = CORRESPONDING short_text_projections( texts )
        exp = VALUE short_text_projections( ( CORRESPONDING #( new_texts[ language = 'D' ] ) ) ) ).
  ENDMETHOD.


  METHOD root_text_no_filter_keeps_rows.
    DATA texts TYPE short_texts.

    " Given two buffered texts in different languages
    DATA(new_texts) = create_buffered_root_texts( ).

    " When following ROOT_TEXT without supplying a filter
    sales_order->read_by_association(
        EXPORTING node        = `ROOT`
                  association = `ROOT_TEXT`
                  keys        = VALUE #( ( key = first_order_key ) )
        IMPORTING rows        = texts
                  failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).

    " Then both languages remain visible regardless of the logon language
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    DATA(actual_texts) = CORRESPONDING short_text_projections( texts ).
    SORT actual_texts BY language.
    cl_abap_unit_assert=>assert_equals(
        act = actual_texts
        exp = CORRESPONDING short_text_projections( new_texts ) ).
  ENDMETHOD.


  METHOD facade_text_filter_limits_rows.
    " Given two buffered languages and the typed demo facade
    DATA(new_texts) = create_buffered_root_texts( ).
    DATA(facade) = NEW zcl_bfw_demo_so_facade( ).

    " When the facade passes a French filter to ROOT.ROOT_TEXT
    DATA(texts) = facade->read_root_root_text(
        keys   = VALUE #( ( key = first_order_key ) )
        filter = VALUE #( language = 'F' ) ).

    " Then the typed reader returns only the buffered French text
    cl_abap_unit_assert=>assert_equals(
        act = CORRESPONDING short_text_projections( texts )
        exp = VALUE short_text_projections( ( CORRESPONDING #( new_texts[ language = 'F' ] ) ) ) ).
  ENDMETHOD.


  METHOD facade_text_no_filter_keeps.
    " Given two buffered languages and the typed demo facade
    DATA(new_texts) = create_buffered_root_texts( ).
    DATA(facade) = NEW zcl_bfw_demo_so_facade( ).

    " When the facade is called without its optional filter
    DATA(texts) = facade->read_root_root_text( VALUE #( ( key = first_order_key ) ) ).

    " Then the initial filter forwarded by the facade leaves both languages visible
    DATA(actual_texts) = CORRESPONDING short_text_projections( texts ).
    SORT actual_texts BY language.
    cl_abap_unit_assert=>assert_equals(
        act = actual_texts
        exp = CORRESPONDING short_text_projections( new_texts ) ).
  ENDMETHOD.


  METHOD facade_path_reads_products.
    " Given a fixture order whose two items reference the saved fixture products
    DATA(facade) = NEW zcl_bfw_demo_so_facade( ).
    DATA(keys) = VALUE /bobf/t_frw_key( ( key = first_order_key ) ).

    " When chaining the order-to-item and item-to-product facade methods
    DATA(products) = facade->read_item_product_root( CORRESPONDING #( facade->read_items( keys ) ) ).

    " Then the cross-BO result contains both configured fixture products
    cl_abap_unit_assert=>assert_equals( act = lines( products )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( products[ product_id = zcl_bfw_test_fixture=>first_product_id ] ) ) ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( products[ product_id = zcl_bfw_test_fixture=>second_product_id ] ) ) ).
    cl_abap_unit_assert=>assert_not_initial(
        products[ product_id = zcl_bfw_test_fixture=>first_product_id ]-key ).
    cl_abap_unit_assert=>assert_not_initial(
        products[ product_id = zcl_bfw_test_fixture=>second_product_id ]-key ).
  ENDMETHOD.


  METHOD unknown_node_raises_access.
    " When resolving an unknown node with nonempty keys
    TRY.
        sales_order->read( node = `UNKNOWN_FIXTURE_NODE`
                           keys = order_keys ).
      CATCH zcx_bfw_access.
        " Then technical name resolution fails through the public exception type
        RETURN.
    ENDTRY.
    cl_abap_unit_assert=>fail( `An unknown node must raise ZCX_BFW_ACCESS` ).
  ENDMETHOD.


  METHOD update_changes_item_amount.
    " Given only KEY and AMOUNT, all other item fields must be preserved
    DATA(expected_items) = read_first_order_items( ).
    DATA(changes) = VALUE item_changes(
        ( key    = expected_items[ item_no = 10 ]-key
          amount = expected_items[ item_no = 10 ]-amount + 1 ) ).

    " When updating without an explicit changed-fields list
    sales_order->update(
        EXPORTING node        = `ITEM`
                  rows        = changes
        IMPORTING failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).

    " Then the buffered state differs only in the requested amount
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    expected_items[ item_no = 10 ]-amount = changes[ 1 ]-amount.
    DATA(actual_items) = read_first_order_items( ).
    SORT expected_items BY key.
    SORT actual_items BY key.
    cl_abap_unit_assert=>assert_equals( act = actual_items
                                        exp = expected_items ).
  ENDMETHOD.


  METHOD create_adds_root_text.
    DATA texts TYPE short_texts.
    " Given the fixture's English text, add another language
    DATA(new_texts) = VALUE short_texts(
        ( parent_key = first_order_key
          language   = 'D'
          text       = 'Buffered integration text' ) ).

    " When creating the child through its configured composition
    sales_order->create(
        EXPORTING node        = `ROOT_TEXT`
        IMPORTING failed_keys = DATA(failed_keys)
                  messages    = DATA(messages)
        CHANGING  rows        = new_texts ).

    " Then a generated key is written back and the new text is associated with the root
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_not_initial( act = new_texts[ 1 ]-key ).
    sales_order->read_by_association(
        EXPORTING node        = `ROOT`
                  association = `ROOT_TEXT`
                  keys        = VALUE #( ( key = first_order_key ) )
        IMPORTING links       = DATA(links)
                  rows        = texts
                  failed_keys = failed_keys
                  messages    = messages ).
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = lines( texts )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( texts[ language = 'E' ] ) ) ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( texts[ key        = new_texts[ 1 ]-key
                                          parent_key = first_order_key
                                          language   = 'D'
                                          text       = new_texts[ 1 ]-text ] ) ) ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( links[ source_key = first_order_key target_key = new_texts[ 1 ]-key ] ) ) ).
  ENDMETHOD.


  METHOD create_adds_long_text_content.
    DATA contents TYPE long_text_contents.
    " Given the DO root created by the business object's determination
    DATA(long_text_root_key) = read_long_text_root_key( ).
    DATA(new_contents) = VALUE long_text_contents(
        ( parent_key   = long_text_root_key
          language     = 'D'
          text_type    = 'MEMO'
          text_content = `Buffered integration memo` ) ).

    " When creating CONTENT below the existing delegated root
    sales_order->create(
        EXPORTING node        = `ROOT_LONG_TEXT.CONTENT`
        IMPORTING failed_keys = DATA(failed_keys)
                  messages    = DATA(messages)
        CHANGING  rows        = new_contents ).

    " Then the generated key and content can be read through the DO composition
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_not_initial( act = new_contents[ 1 ]-key ).
    sales_order->read_by_association(
        EXPORTING node        = `ROOT_LONG_TEXT`
                  association = `CONTENT`
                  keys        = VALUE #( ( key = long_text_root_key ) )
        IMPORTING links       = DATA(links)
                  rows        = contents
                  failed_keys = failed_keys
                  messages    = messages ).
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = lines( contents )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( contents[ key          = new_contents[ 1 ]-key
                                             parent_key   = long_text_root_key
                                             language     = 'D'
                                             text_type    = 'MEMO'
                                             text_content = new_contents[ 1 ]-text_content ] ) ) ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( links[ source_key = long_text_root_key target_key = new_contents[ 1 ]-key ] ) ) ).
  ENDMETHOD.


  METHOD delete_makes_item_unreadable.
    DATA remaining_items TYPE items.
    DATA(order_items) = read_first_order_items( ).
    DATA(deleted_keys) = VALUE zif_bfw_business_object=>keys( ( key = order_items[ item_no = 20 ]-key ) ).

    " When deleting an item in the transactional buffer
    sales_order->delete(
        EXPORTING node        = `ITEM`
                  keys        = deleted_keys
        IMPORTING failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).

    " Then reading that key returns no row and reports it as failed
    sales_order->read(
        EXPORTING node        = `ITEM`
                  keys        = deleted_keys
        IMPORTING rows        = remaining_items
                  failed_keys = failed_keys ).
    cl_abap_unit_assert=>assert_initial( remaining_items ).
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = deleted_keys ).
  ENDMETHOD.


  METHOD deliver_marks_requested_item.
    " Given an existing, undelivered item as required by the demo action validation
    DATA(order_items) = read_first_order_items( ).
    cl_abap_unit_assert=>assert_initial( order_items[ item_no = 10 ]-delivered ).

    " When delivering item 10 through the parameterized root action
    sales_order->execute_action(
        EXPORTING node        = `ROOT`
                  action      = `DELIVER`
                  keys        = VALUE #( ( key = first_order_key ) )
                  parameters  = VALUE /bobf/s_demo_sales_order_hdr_d( item_no = 10 )
        IMPORTING failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).

    " Then only the requested item is marked delivered in the buffer
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    DATA(delivered_items) = read_first_order_items( ).
    cl_abap_unit_assert=>assert_equals( act = delivered_items[ item_no = 10 ]-delivered
                                        exp = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = delivered_items[ item_no = 20 ]-delivered
                                        exp = order_items[ item_no = 20 ]-delivered ).
  ENDMETHOD.


  METHOD archive_marks_order.
    DATA orders TYPE /bobf/t_demo_sales_order_hdr_k.

    " When executing the root action without parameters
    sales_order->execute_action(
        EXPORTING node        = `ROOT`
                  action      = `ARCHIVE`
                  keys        = VALUE #( ( key = first_order_key ) )
        IMPORTING failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).

    " Then the demo action marks the buffered order for archiving
    sales_order->read(
        EXPORTING node        = `ROOT`
                  keys        = VALUE #( ( key = first_order_key ) )
        IMPORTING rows        = orders
                  failed_keys = failed_keys
                  messages    = messages ).
    assert_no_errors( messages ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = lines( orders )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
        act = orders[ 1 ]-archiv_status
        exp = /bobf/if_demo_sales_order_ic=>sc_archiving_status-marked_4_archiving ).
  ENDMETHOD.
ENDCLASS.
