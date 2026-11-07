CLASS ltcl_facade_generator DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS business_object_name TYPE string VALUE `/BOBF/DEMO_SALES_ORDER`.

    DATA generator TYPE REF TO zcl_bfw_facade_generator.

    METHODS setup.
    METHODS build_facade
      IMPORTING
        selection_lines TYPE string_table
      RETURNING
        VALUE(result)   TYPE zcl_bfw_facade_generator=>facade.

    METHODS selection_is_normalized FOR TESTING.
    METHODS missing_name_is_rejected FOR TESTING.
    METHODS unknown_kind_is_rejected FOR TESTING.
    METHODS association_requires_dot FOR TESTING.
    METHODS root_facade_has_identity FOR TESTING.
    METHODS constructor_calls_factory FOR TESTING.
    METHODS selection_method_is_static FOR TESTING.
    METHODS root_read_has_typed_keys FOR TESTING.
    METHODS item_create_changes_rows FOR TESTING.
    METHODS item_update_has_field_filter FOR TESTING.
    METHODS item_delete_has_keys FOR TESTING.
    METHODS associations_use_target_types FOR TESTING.
    METHODS short_text_assoc_has_filter FOR TESTING.
    METHODS item_association_omits_filter FOR TESTING.
    METHODS dependent_nodes_are_qualified FOR TESTING.
    METHODS short_text_read_is_typed FOR TESTING.
    METHODS alternative_key_has_values FOR TESTING.
    METHODS query_has_optional_filters FOR TESTING.
    METHODS query_forwards_read_options FOR TESTING.
    METHODS deliver_has_parameters FOR TESTING.
    METHODS archive_omits_parameters FOR TESTING.
    METHODS unknown_node_is_reported FOR TESTING.
    METHODS unknown_bo_is_reported FOR TESTING.
    METHODS long_class_name_is_rejected FOR TESTING.
    METHODS long_method_name_is_reported FOR TESTING.
    METHODS duplicate_methods_are_reported FOR TESTING.
    METHODS entry_error_allows_other_nodes FOR TESTING.
    METHODS selection_source_round_trips FOR TESTING.
    METHODS marker_identifies_generated FOR TESTING.
ENDCLASS.



CLASS ltcl_facade_generator IMPLEMENTATION.

  METHOD setup.
    " Given a fresh generator using the real classic BOPF configuration
    generator = NEW #( ).
  ENDMETHOD.


  METHOD build_facade.
    generator->build(
        EXPORTING business_object = business_object_name
                  class_name      = `zcl_bfw_order_facade`
                  selection       = selection_lines
        IMPORTING facade          = result
                  errors          = DATA(errors) ).
    cl_abap_unit_assert=>assert_initial( errors ).
  ENDMETHOD.


  METHOD selection_is_normalized.
    " Given mixed case, extra blanks, aliases and empty lines
    DATA(selection_lines) = VALUE string_table( ( `  NoDe   rOoT  =  HeAdEr  ` )
                                                ( `` )
                                                ( `   ` )
                                                ( `  WrItAbLe_NoDe  iTeM = ItEmS  ` )
                                                ( ` Association  root.item = OrderItems ` )
                                                ( ` node root_text ` ) ).

    " When parsing the selection
    generator->parse_selection(
        EXPORTING selection = selection_lines
        IMPORTING entries   = DATA(entries)
                  errors    = DATA(errors) ).

    " Then names are uppercase, kinds and aliases lowercase, and blank lines disappear
    cl_abap_unit_assert=>assert_initial( errors ).
    cl_abap_unit_assert=>assert_equals(
        act = entries
        exp = VALUE zcl_bfw_facade_generator=>selection_entries(
            ( kind = `node`          name = `ROOT`      alias = `header` )
            ( kind = `writable_node` name = `ITEM`      alias = `items` )
            ( kind = `association`   name = `ROOT.ITEM` alias = `orderitems` )
            ( kind = `node`          name = `ROOT_TEXT` ) ) ).
  ENDMETHOD.


  METHOD missing_name_is_rejected.
    " Given a kind without its required name
    DATA(selection_lines) = VALUE string_table( ( `node` ) ).

    " When parsing the incomplete line
    generator->parse_selection(
        EXPORTING selection = selection_lines
        IMPORTING entries   = DATA(entries)
                  errors    = DATA(errors) ).

    " Then the line contributes one error and no entry
    cl_abap_unit_assert=>assert_initial( entries ).
    cl_abap_unit_assert=>assert_equals(
        act = errors
        exp = VALUE string_table( ( `Line "node" does not have the form: kind name [= alias]` ) ) ).
  ENDMETHOD.


  METHOD unknown_kind_is_rejected.
    " Given a name with an unsupported kind
    DATA(selection_lines) = VALUE string_table( ( `table ROOT` ) ).

    " When parsing the unsupported line
    generator->parse_selection(
        EXPORTING selection = selection_lines
        IMPORTING entries   = DATA(entries)
                  errors    = DATA(errors) ).

    " Then the line contributes one error and no entry
    cl_abap_unit_assert=>assert_initial( entries ).
    cl_abap_unit_assert=>assert_equals(
        act = errors
        exp = VALUE string_table( ( `Line "table ROOT": unknown kind table` ) ) ).
  ENDMETHOD.


  METHOD association_requires_dot.
    " Given an association without a node.member name
    DATA(selection_lines) = VALUE string_table( ( `association ROOT` ) ).

    " When parsing the unqualified association
    generator->parse_selection(
        EXPORTING selection = selection_lines
        IMPORTING entries   = DATA(entries)
                  errors    = DATA(errors) ).

    " Then the line contributes one error and no entry
    cl_abap_unit_assert=>assert_initial( entries ).
    cl_abap_unit_assert=>assert_equals(
        act = errors
        exp = VALUE string_table( ( `Line "association ROOT": association needs a name of the form node.name` ) ) ).
  ENDMETHOD.


  METHOD root_facade_has_identity.
    " Given lowercase names surrounded by blanks
    DATA(selection_lines) = VALUE string_table( ( `node ROOT` ) ).

    " When building a root facade from the real configuration
    generator->build(
        EXPORTING business_object = `  /bobf/demo_sales_order  `
                  class_name      = `  zcl_bfw_order_facade  `
                  selection       = selection_lines
        IMPORTING facade          = DATA(facade)
                  errors          = DATA(errors) ).

    " Then the normalized identity and private engine describe the sales-order facade
    cl_abap_unit_assert=>assert_initial( errors ).
    cl_abap_unit_assert=>assert_equals(
        act = facade-class_name
        exp = `ZCL_BFW_ORDER_FACADE` ).
    cl_abap_unit_assert=>assert_equals(
        act = facade-business_object
        exp = business_object_name ).
    cl_abap_unit_assert=>assert_equals(
        act = facade-description
        exp = `Generated facade of /BOBF/DEMO_SALES_ORDER` ).
    cl_abap_unit_assert=>assert_equals(
        act = facade-attributes
        exp = VALUE zcl_bfw_facade_generator=>facade_attributes(
            ( name           = `ENGINE`
              interface_name = `ZIF_BFW_BUSINESS_OBJECT` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lines( facade-methods )
        exp = 3 ).
  ENDMETHOD.


  METHOD constructor_calls_factory.
    " Given a selection containing the root node
    DATA(selection_lines) = VALUE string_table( ( `node ROOT` ) ).

    " When building its facade
    DATA(facade) = build_facade( selection_lines ).

    " Then the instance constructor obtains exactly the selected business object
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `CONSTRUCTOR` ]
        exp = VALUE zcl_bfw_facade_generator=>facade_method(
            name   = `CONSTRUCTOR`
            source = VALUE #( ( `    engine = zcl_bfw_factory=>get_business_object( ``/BOBF/DEMO_SALES_ORDER`` ).` ) ) ) ).
  ENDMETHOD.


  METHOD selection_method_is_static.
    " Given two selections whose names and alias need normalization
    DATA(selection_lines) = VALUE string_table( ( ` NoDe root ` )
                                                ( ` node root_text = TeXtS ` ) ).

    " When building the selection method
    DATA(facade) = build_facade( selection_lines ).

    " Then a static method returns STRING_TABLE and stores the marker before the exact selection source
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `GET_SELECTION` ]
        exp = VALUE zcl_bfw_facade_generator=>facade_method(
            name       = `GET_SELECTION`
            is_static  = abap_true
            parameters = VALUE #( ( name      = `RESULT`
                                    direction = 'R'
                                    type_name = `STRING_TABLE` ) )
            source     = VALUE #( ( |    { zcl_bfw_facade_generator=>marker }| )
                                  ( `    result = VALUE #( ( ``node ROOT`` )` )
                                  ( `                      ( ``node ROOT_TEXT = texts`` ) ).` ) ) ) ).
  ENDMETHOD.


  METHOD root_read_has_typed_keys.
    " Given a root-node selection
    DATA(selection_lines) = VALUE string_table( ( `node ROOT` ) ).

    " When building its read method
    DATA(facade) = build_facade( selection_lines ).

    " Then BOPF keys are converted and the aligned engine call returns the configured root table
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `READ_ROOT` ]
        exp = VALUE zcl_bfw_facade_generator=>facade_method(
            name       = `READ_ROOT`
            parameters = VALUE #( ( name      = `KEYS`
                                    direction = 'I'
                                    type_name = `/BOBF/T_FRW_KEY` )
                                  ( name      = `RESULT`
                                    direction = 'R'
                                    type_name = `/BOBF/T_DEMO_SALES_ORDER_HDR_K` ) )
            source     = VALUE #( ( `    engine->read( EXPORTING node = ``ROOT``` )
                                  ( `                            keys = CORRESPONDING #( keys )` )
                                  ( `                  IMPORTING rows = result ).` ) ) ) ).
  ENDMETHOD.


  METHOD item_create_changes_rows.
    " Given a writable node with an alias
    DATA(selection_lines) = VALUE string_table( ( `writable_node ITEM = items` ) ).

    " When building its create method
    DATA(facade) = build_facade( selection_lines ).

    " Then rows are changing, outputs are typed, and engine failed keys are converted after the exact call
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `CREATE_ITEMS` ]
        exp = VALUE zcl_bfw_facade_generator=>facade_method(
            name       = `CREATE_ITEMS`
            parameters = VALUE #( ( name      = `FAILED_KEYS`
                                    direction = 'E'
                                    type_name = `/BOBF/T_FRW_KEY` )
                                  ( name      = `MESSAGES`
                                    direction = 'E'
                                    type_name = `ZIF_BFW_BUSINESS_OBJECT=>MESSAGES` )
                                  ( name      = `ROWS`
                                    direction = 'C'
                                    type_name = `/BOBF/T_DEMO_SALES_ORDER_ITM_K` ) )
            source     = VALUE #( ( `    DATA engine_failed_keys TYPE zif_bfw_business_object=>keys.` )
                                  ( `` )
                                  ( `    engine->create( EXPORTING node        = ``ITEM``` )
                                  ( `                    IMPORTING failed_keys = engine_failed_keys` )
                                  ( `                              messages    = messages` )
                                  ( `                    CHANGING  rows        = rows ).` )
                                  ( `    failed_keys = CORRESPONDING #( engine_failed_keys ).` ) ) ) ).
  ENDMETHOD.


  METHOD item_update_has_field_filter.
    " Given a writable item selection
    DATA(selection_lines) = VALUE string_table( ( `writable_node ITEM = items` ) ).

    " When building its update method
    DATA(facade) = build_facade( selection_lines ).

    " Then only CHANGED_FIELDS is optional and rows remain an importing item table
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `UPDATE_ITEMS` ]-parameters
        exp = VALUE zcl_bfw_facade_generator=>method_parameters(
            ( name      = `ROWS`
              direction = 'I'
              type_name = `/BOBF/T_DEMO_SALES_ORDER_ITM_K` )
            ( name        = `CHANGED_FIELDS`
              direction   = 'I'
              type_name   = `ZIF_BFW_BUSINESS_OBJECT=>FIELD_NAMES`
              is_optional = abap_true )
            ( name      = `FAILED_KEYS`
              direction = 'E'
              type_name = `/BOBF/T_FRW_KEY` )
            ( name      = `MESSAGES`
              direction = 'E'
              type_name = `ZIF_BFW_BUSINESS_OBJECT=>MESSAGES` ) ) ).
  ENDMETHOD.


  METHOD item_delete_has_keys.
    " Given a writable item selection
    DATA(selection_lines) = VALUE string_table( ( `writable_node ITEM = items` ) ).

    " When building its delete method
    DATA(facade) = build_facade( selection_lines ).

    " Then required keys are importing and the failure and message outputs have their public types
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `DELETE_ITEMS` ]-parameters
        exp = VALUE zcl_bfw_facade_generator=>method_parameters(
            ( name      = `KEYS`
              direction = 'I'
              type_name = `/BOBF/T_FRW_KEY` )
            ( name      = `FAILED_KEYS`
              direction = 'E'
              type_name = `/BOBF/T_FRW_KEY` )
            ( name      = `MESSAGES`
              direction = 'E'
              type_name = `ZIF_BFW_BUSINESS_OBJECT=>MESSAGES` ) ) ).
  ENDMETHOD.


  METHOD associations_use_target_types.
    " Given local, cross-BO and dependent-object associations
    DATA(selection_lines) = VALUE string_table( ( `association ROOT.ITEM` )
                                                ( `association ROOT.CUSTOMER_ROOT` )
                                                ( `association ROOT.ROOT_LONG_TEXT` ) ).

    " When building all three association readers
    DATA(facade) = build_facade( selection_lines ).

    " Then each returning parameter uses the target configuration rather than the source root type
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `READ_ROOT_ITEM` ]-parameters[ name = `RESULT` ]
        exp = VALUE zcl_bfw_facade_generator=>method_parameter(
            name      = `RESULT`
            direction = 'R'
            type_name = `/BOBF/T_DEMO_SALES_ORDER_ITM_K` ) ).
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `READ_ROOT_CUSTOMER_ROOT` ]-parameters[ name = `RESULT` ]
        exp = VALUE zcl_bfw_facade_generator=>method_parameter(
            name      = `RESULT`
            direction = 'R'
            type_name = `/BOBF/T_DEMO_CUSTOMER_HDR_K` ) ).
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `READ_ROOT_ROOT_LONG_TEXT` ]-parameters[ name = `RESULT` ]
        exp = VALUE zcl_bfw_facade_generator=>method_parameter(
            name      = `RESULT`
            direction = 'R'
            type_name = `/BOBF/T_DEMO_LONGTEXT_HDR_K` ) ).
  ENDMETHOD.


  METHOD short_text_assoc_has_filter.
    " Given the parameterized ROOT.ROOT_TEXT association
    DATA(selection_lines) = VALUE string_table( ( `association ROOT.ROOT_TEXT` ) ).

    " When building its association reader
    DATA(facade) = build_facade( selection_lines ).

    " Then the optional language filter has the configured type and is passed to the engine
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `READ_ROOT_ROOT_TEXT` ]
        exp = VALUE zcl_bfw_facade_generator=>facade_method(
            name       = `READ_ROOT_ROOT_TEXT`
            parameters = VALUE #( ( name      = `KEYS`
                                    direction = 'I'
                                    type_name = `/BOBF/T_FRW_KEY` )
                                  ( name        = `FILTER`
                                    direction   = 'I'
                                    type_name   = `/BOBF/S_DEMO_LANGUAGE_CODE`
                                    is_optional = abap_true )
                                  ( name      = `RESULT`
                                    direction = 'R'
                                    type_name = `/BOBF/T_DEMO_SHORT_TEXT_K` ) )
            source     = VALUE #( ( `    engine->read_by_association( EXPORTING node        = ``ROOT``` )
                                  ( `                                           association = ``ROOT_TEXT``` )
                                  ( `                                           keys        = CORRESPONDING #( keys )` )
                                  ( `                                           filter      = filter` )
                                  ( `                                 IMPORTING rows        = result ).` ) ) ) ).
  ENDMETHOD.


  METHOD item_association_omits_filter.
    " Given ROOT.ITEM without association parameters
    DATA(selection_lines) = VALUE string_table( ( `association ROOT.ITEM` ) ).

    " When building its association reader
    DATA(facade) = build_facade( selection_lines ).

    " Then neither the signature nor the engine call contains a filter
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `READ_ROOT_ITEM` ]
        exp = VALUE zcl_bfw_facade_generator=>facade_method(
            name       = `READ_ROOT_ITEM`
            parameters = VALUE #( ( name      = `KEYS`
                                    direction = 'I'
                                    type_name = `/BOBF/T_FRW_KEY` )
                                  ( name      = `RESULT`
                                    direction = 'R'
                                    type_name = `/BOBF/T_DEMO_SALES_ORDER_ITM_K` ) )
            source     = VALUE #( ( `    engine->read_by_association( EXPORTING node        = ``ROOT``` )
                                  ( `                                           association = ``ITEM``` )
                                  ( `                                           keys        = CORRESPONDING #( keys )` )
                                  ( `                                 IMPORTING rows        = result ).` ) ) ) ).
  ENDMETHOD.


  METHOD dependent_nodes_are_qualified.
    " Given the delegated long-text root and its qualified child
    DATA(selection_lines) = VALUE string_table( ( `node ROOT_LONG_TEXT` )
                                                ( `node ROOT_LONG_TEXT.CONTENT` ) ).

    " When building readers for both dependent-object nodes
    DATA(facade) = build_facade( selection_lines ).

    " Then dots become underscores in method names and each node retains its own table type
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `READ_ROOT_LONG_TEXT` ]-parameters[ name = `RESULT` ]-type_name
        exp = `/BOBF/T_DEMO_LONGTEXT_HDR_K` ).
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `READ_ROOT_LONG_TEXT_CONTENT` ]-parameters
        exp = VALUE zcl_bfw_facade_generator=>method_parameters(
            ( name      = `KEYS`
              direction = 'I'
              type_name = `/BOBF/T_FRW_KEY` )
            ( name      = `RESULT`
              direction = 'R'
              type_name = `/BOBF/T_DEMO_LONGTEXT_ITEM_K` ) ) ).
  ENDMETHOD.


  METHOD short_text_read_is_typed.
    " Given the sales order's short-text node
    DATA(selection_lines) = VALUE string_table( ( `node ROOT_TEXT` ) ).

    " When building its reader
    DATA(facade) = build_facade( selection_lines ).

    " Then its returning type comes from the short-text configuration
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `READ_ROOT_TEXT` ]-parameters[ name = `RESULT` ]
        exp = VALUE zcl_bfw_facade_generator=>method_parameter(
            name      = `RESULT`
            direction = 'R'
            type_name = `/BOBF/T_DEMO_SHORT_TEXT_K` ) ).
  ENDMETHOD.


  METHOD alternative_key_has_values.
    " Given the root's ORDER_ID alternative key
    DATA(selection_lines) = VALUE string_table( ( `alternative_key ROOT.ORDER_ID` ) ).

    " When building its conversion method
    DATA(facade) = build_facade( selection_lines ).

    " Then VALUES imports the configured alternative-key table and RESULT returns sales-order roots
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `READ_ROOT_BY_ORDER_ID` ]-parameters
        exp = VALUE zcl_bfw_facade_generator=>method_parameters(
            ( name      = `VALUES`
              direction = 'I'
              type_name = `/BOBF/T_DEMO_SALES_ORDER_ID` )
            ( name      = `RESULT`
              direction = 'R'
              type_name = `/BOBF/T_DEMO_SALES_ORDER_HDR_K` ) ) ).
  ENDMETHOD.


  METHOD query_has_optional_filters.
    " Given both configured root queries
    DATA(selection_lines) = VALUE string_table( ( `query ROOT.SELECT_ALL` )
                                                ( `query ROOT.SELECT_BY_ELEMENTS` ) ).
    DATA(expected_parameters) = VALUE zcl_bfw_facade_generator=>method_parameters(
        ( name        = `SELECTION_PARAMETERS`
          direction   = 'I'
          type_name   = `ZIF_BFW_BUSINESS_OBJECT=>SELECTION_PARAMETERS`
          is_optional = abap_true )
        ( name        = `FILTER_KEYS`
          direction   = 'I'
          type_name   = `/BOBF/T_FRW_KEY`
          is_optional = abap_true )
        ( name          = `MAXIMUM_ROWS`
          direction     = 'I'
          type_name     = `I`
          default_value = `0` )
        ( name        = `SORTING`
          direction   = 'I'
          type_name   = `ZIF_BFW_BUSINESS_OBJECT=>SORTING`
          is_optional = abap_true )
        ( name        = `PAGING`
          direction   = 'I'
          type_name   = `ZIF_BFW_BUSINESS_OBJECT=>PAGING`
          is_optional = abap_true )
        ( name      = `RESULT`
          direction = 'R'
          type_name = `/BOBF/T_DEMO_SALES_ORDER_HDR_K` ) ).

    " When building their query methods
    DATA(facade) = build_facade( selection_lines ).

    " Then filters are optional, the row limit defaults to zero and results use the root table
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `QUERY_SELECT_ALL` ]-parameters
        exp = expected_parameters ).
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `QUERY_SELECT_BY_ELEMENTS` ]-parameters
        exp = expected_parameters ).
  ENDMETHOD.


  METHOD query_forwards_read_options.
    " Given the element-filter query with the optional read options
    DATA(selection_lines) = VALUE string_table( ( `query ROOT.SELECT_BY_ELEMENTS` ) ).

    " When building its query method
    DATA(facade) = build_facade( selection_lines ).

    " Then filter keys are converted and selection, limit, sorting and paging reach the engine
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `QUERY_SELECT_BY_ELEMENTS` ]-source
        exp = VALUE string_table(
            ( `    engine->query( EXPORTING node                 = ``ROOT``` )
            ( `                             query                = ``SELECT_BY_ELEMENTS``` )
            ( `                             selection_parameters = selection_parameters` )
            ( `                             filter_keys          = CORRESPONDING #( filter_keys )` )
            ( `                             maximum_rows         = maximum_rows` )
            ( `                             sorting              = sorting` )
            ( `                             paging               = paging` )
            ( `                   IMPORTING rows                 = result ).` ) ) ).
  ENDMETHOD.


  METHOD deliver_has_parameters.
    " Given the configured DELIVER action with parameters and no result
    DATA(selection_lines) = VALUE string_table( ( `action ROOT.DELIVER` ) ).

    " When building its action method
    DATA(facade) = build_facade( selection_lines ).

    " Then keys and parameters are optional and only failure keys and messages are exported
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `EXECUTE_DELIVER` ]-parameters
        exp = VALUE zcl_bfw_facade_generator=>method_parameters(
            ( name        = `KEYS`
              direction   = 'I'
              type_name   = `/BOBF/T_FRW_KEY`
              is_optional = abap_true )
            ( name        = `PARAMETERS`
              direction   = 'I'
              type_name   = `/BOBF/S_DEMO_SALES_ORDER_HDR_D`
              is_optional = abap_true )
            ( name      = `FAILED_KEYS`
              direction = 'E'
              type_name = `/BOBF/T_FRW_KEY` )
            ( name      = `MESSAGES`
              direction = 'E'
              type_name = `ZIF_BFW_BUSINESS_OBJECT=>MESSAGES` ) ) ).
  ENDMETHOD.


  METHOD archive_omits_parameters.
    " Given the configured ARCHIVE action without parameters or a result
    DATA(selection_lines) = VALUE string_table( ( `action ROOT.ARCHIVE` ) ).

    " When building its action method
    DATA(facade) = build_facade( selection_lines ).

    " Then neither PARAMETERS nor ROWS occurs in the signature
    cl_abap_unit_assert=>assert_equals(
        act = facade-methods[ name = `EXECUTE_ARCHIVE` ]-parameters
        exp = VALUE zcl_bfw_facade_generator=>method_parameters(
            ( name        = `KEYS`
              direction   = 'I'
              type_name   = `/BOBF/T_FRW_KEY`
              is_optional = abap_true )
            ( name      = `FAILED_KEYS`
              direction = 'E'
              type_name = `/BOBF/T_FRW_KEY` )
            ( name      = `MESSAGES`
              direction = 'E'
              type_name = `ZIF_BFW_BUSINESS_OBJECT=>MESSAGES` ) ) ).
  ENDMETHOD.


  METHOD unknown_node_is_reported.
    " Given a syntactically valid node name absent from the configuration
    DATA(selection_lines) = VALUE string_table( ( `node MISSING_NODE` ) ).

    " When building the facade
    generator->build(
        EXPORTING business_object = business_object_name
                  class_name      = `ZCL_BFW_ORDER_FACADE`
                  selection       = selection_lines
        IMPORTING facade          = DATA(facade)
                  errors          = DATA(errors) ).

    " Then one contextual error is returned and only the two scaffold methods remain
    cl_abap_unit_assert=>assert_equals(
        act = lines( errors )
        exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
        act = xsdbool( errors[ 1 ] CP 'node MISSING_NODE: *' )
        exp = abap_true ).
    cl_abap_unit_assert=>assert_equals(
        act = lines( facade-methods )
        exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
        act = xsdbool( line_exists( facade-methods[ name = `READ_MISSING_NODE` ] ) )
        exp = abap_false ).
  ENDMETHOD.


  METHOD unknown_bo_is_reported.
    " Given a business object that does not exist
    DATA(selection_lines) = VALUE string_table( ( `node ROOT` ) ).

    " When the factory cannot resolve its configuration
    generator->build(
        EXPORTING business_object = `ZBFW_UNKNOWN_BUSINESS_OBJECT`
                  class_name      = `ZCL_BFW_ORDER_FACADE`
                  selection       = selection_lines
        IMPORTING facade          = DATA(facade)
                  errors          = DATA(errors) ).

    " Then an error identifies the missing business object and no facade is produced
    cl_abap_unit_assert=>assert_equals(
        act = lines( errors )
        exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
        act = xsdbool( errors[ 1 ] CS `ZBFW_UNKNOWN_BUSINESS_OBJECT` )
        exp = abap_true ).
    cl_abap_unit_assert=>assert_initial( facade ).
  ENDMETHOD.


  METHOD long_class_name_is_rejected.
    " Given a class name just beyond the thirty-character limit
    DATA(selection_lines) = VALUE string_table( ( `node ROOT` ) ).

    " When validating the requested class name
    generator->build(
        EXPORTING business_object = business_object_name
                  class_name      = `Z123456789012345678901234567890`
                  selection       = selection_lines
        IMPORTING facade          = DATA(facade)
                  errors          = DATA(errors) ).

    " Then validation returns its exact error before producing a facade
    cl_abap_unit_assert=>assert_equals(
        act = errors
        exp = VALUE string_table( ( `Class name Z123456789012345678901234567890 must have 1 to 30 characters` ) ) ).
    cl_abap_unit_assert=>assert_initial( facade ).
  ENDMETHOD.


  METHOD long_method_name_is_reported.
    " Given an alias whose READ_ method name has thirty-one characters
    DATA(selection_lines) = VALUE string_table( ( `node ROOT = abcdefghijklmnopqrstuvwxyz` ) ).

    " When checking the generated method names
    generator->build(
        EXPORTING business_object = business_object_name
                  class_name      = `ZCL_BFW_ORDER_FACADE`
                  selection       = selection_lines
        IMPORTING facade          = DATA(facade)
                  errors          = DATA(errors) ).

    " Then the overlong method is reported without hiding the model
    cl_abap_unit_assert=>assert_equals(
        act = errors
        exp = VALUE string_table(
            ( `Method name READ_ABCDEFGHIJKLMNOPQRSTUVWXYZ is longer than 30 characters; give its entry an alias` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = xsdbool( line_exists( facade-methods[ name = `READ_ABCDEFGHIJKLMNOPQRSTUVWXYZ` ] ) )
        exp = abap_true ).
  ENDMETHOD.


  METHOD duplicate_methods_are_reported.
    " Given two different nodes with the same method alias
    DATA(selection_lines) = VALUE string_table( ( `node ROOT = rows` )
                                                ( `node ITEM = rows` ) ).

    " When checking the generated method names
    generator->build(
        EXPORTING business_object = business_object_name
                  class_name      = `ZCL_BFW_ORDER_FACADE`
                  selection       = selection_lines
        IMPORTING facade          = DATA(facade)
                  errors          = DATA(errors) ).

    " Then the collision is reported even though both entries resolve to valid nodes
    cl_abap_unit_assert=>assert_equals(
        act = errors
        exp = VALUE string_table(
            ( `Method name READ_ROWS is generated twice; give one of its entries an alias` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = lines( facade-methods )
        exp = 4 ).
  ENDMETHOD.


  METHOD entry_error_allows_other_nodes.
    " Given valid nodes before and after an unknown node
    DATA(selection_lines) = VALUE string_table( ( `node ROOT` )
                                                ( `node MISSING_NODE` )
                                                ( `node ITEM` ) ).

    " When one entry fails during metadata resolution
    generator->build(
        EXPORTING business_object = business_object_name
                  class_name      = `ZCL_BFW_ORDER_FACADE`
                  selection       = selection_lines
        IMPORTING facade          = DATA(facade)
                  errors          = DATA(errors) ).

    " Then both valid entries still contribute methods and only the unknown node contributes an error
    cl_abap_unit_assert=>assert_equals(
        act = lines( errors )
        exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
        act = xsdbool( errors[ 1 ] CP 'node MISSING_NODE: *' )
        exp = abap_true ).
    cl_abap_unit_assert=>assert_equals(
        act = lines( facade-methods )
        exp = 4 ).
    cl_abap_unit_assert=>assert_equals(
        act = xsdbool( line_exists( facade-methods[ name = `READ_ROOT` ] ) )
        exp = abap_true ).
    cl_abap_unit_assert=>assert_equals(
        act = xsdbool( line_exists( facade-methods[ name = `READ_ITEM` ] ) )
        exp = abap_true ).
  ENDMETHOD.


  METHOD selection_source_round_trips.
    " Given a built facade with mixed-case selections, an alias and empty lines
    DATA(facade) = build_facade( VALUE #( ( ` NoDe  root ` )
                                         ( `` )
                                         ( ` Association root.item = ItEmS ` )
                                         ( `   ` )
                                         ( ` Query root.select_by_elements ` ) ) ).

    " When reading the generated GET_SELECTION source
    DATA(selection_lines) = generator->get_selection_from_source( facade-methods[ name = `GET_SELECTION` ]-source ).

    " Then the normalized lines preserve order and aliases without empty entries
    cl_abap_unit_assert=>assert_equals(
        act = selection_lines
        exp = VALUE string_table( ( `node ROOT` )
                                  ( `association ROOT.ITEM = items` )
                                  ( `query ROOT.SELECT_BY_ELEMENTS` ) ) ).
  ENDMETHOD.


  METHOD marker_identifies_generated.
    " Given generated source, empty source and source without the marker
    DATA(facade) = build_facade( VALUE #( ( `node ROOT` ) ) ).
    DATA(empty_source_lines) = VALUE string_table( ).
    DATA(unmarked_source_lines) = VALUE string_table( ( `    result = VALUE #( ( ``node ROOT`` ) ).` ) ).

    " When recognizing the three method bodies
    DATA(generated) = generator->is_generated_source( facade-methods[ name = `GET_SELECTION` ]-source ).
    DATA(empty_generated) = generator->is_generated_source( empty_source_lines ).
    DATA(unmarked_generated) = generator->is_generated_source( unmarked_source_lines ).

    " Then only the body starting with the generator marker is recognized
    cl_abap_unit_assert=>assert_equals(
        act = generated
        exp = abap_true ).
    cl_abap_unit_assert=>assert_equals(
        act = empty_generated
        exp = abap_false ).
    cl_abap_unit_assert=>assert_equals(
        act = unmarked_generated
        exp = abap_false ).
  ENDMETHOD.
ENDCLASS.
