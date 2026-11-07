CLASS ltcl_metadata DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA metadata TYPE REF TO zcl_bfw_metadata.

    METHODS setup RAISING /bobf/cx_frw /bobf/cx_frw_contrct_violation.
    METHODS nodes_include_business_nodes FOR TESTING.
    METHODS nodes_include_dependent_nodes FOR TESTING.
    METHODS nodes_have_table_type_info FOR TESTING.
    METHODS nodes_exclude_technical_nodes FOR TESTING.
    METHODS associations_are_qualified FOR TESTING.
    METHODS associations_have_node_targets FOR TESTING.
    METHODS text_assoc_has_parameter_type FOR TESTING.
    METHODS item_assoc_has_no_parameters FOR TESTING.
    METHODS dependent_assocs_are_listed FOR TESTING.
    METHODS cross_bo_targets_name_objects FOR TESTING.
    METHODS technical_assocs_are_excluded FOR TESTING.
    METHODS alternative_keys_are_qualified FOR TESTING.
    METHODS deliver_has_parameter_info FOR TESTING.
    METHODS archive_has_no_parameter_info FOR TESTING.
    METHODS queries_are_qualified FOR TESTING.
    METHODS unknown_kind_has_no_names FOR TESTING.
ENDCLASS.



CLASS ltcl_metadata IMPLEMENTATION.

  METHOD setup.
    " Given fresh metadata from the real sales-order configuration without instance data
    metadata = NEW zcl_bfw_metadata(
        /bobf/cl_frw_factory=>get_configuration(
            /bobf/cl_frw_factory=>query_bo( '/BOBF/DEMO_SALES_ORDER' ) ) ).
  ENDMETHOD.


  METHOD nodes_include_business_nodes.
    " Given the sales-order configuration
    " When listing selectable nodes
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-node ).

    " Then root, item and their short-text nodes are selectable
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT` ] ) )
        msg = `ROOT must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ITEM` ] ) )
        msg = `ITEM must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT_TEXT` ] ) )
        msg = `ROOT_TEXT must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ITEM_TEXT` ] ) )
        msg = `ITEM_TEXT must be selectable` ).
  ENDMETHOD.


  METHOD nodes_include_dependent_nodes.
    " Given the sales-order configuration with root and item long-text dependent objects
    " When listing selectable nodes
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-node ).

    " Then each dependent root and its qualified content node are selectable
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT_LONG_TEXT` ] ) )
        msg = `ROOT_LONG_TEXT must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT_LONG_TEXT.CONTENT` ] ) )
        msg = `ROOT_LONG_TEXT.CONTENT must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ITEM_LONG_TEXT` ] ) )
        msg = `ITEM_LONG_TEXT must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ITEM_LONG_TEXT.CONTENT` ] ) )
        msg = `ITEM_LONG_TEXT.CONTENT must be selectable` ).
  ENDMETHOD.


  METHOD nodes_have_table_type_info.
    " Given the sales-order configuration
    " When listing selectable nodes
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-node ).

    " Then every returned node includes its table type
    cl_abap_unit_assert=>assert_not_initial( names ).
    LOOP AT names ASSIGNING FIELD-SYMBOL(<name>).
      cl_abap_unit_assert=>assert_not_initial(
          act = <name>-info
          msg = |Node { <name>-name } must include its table type| ).
    ENDLOOP.
  ENDMETHOD.


  METHOD nodes_exclude_technical_nodes.
    " Given the sales-order configuration with message, property and lock nodes
    " When listing selectable nodes
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-node ).

    " Then technical nodes are omitted
    cl_abap_unit_assert=>assert_not_initial( names ).
    cl_abap_unit_assert=>assert_false(
        act = xsdbool( line_exists( names[ name = `ROOT_MESSAGE` ] ) )
        msg = `ROOT_MESSAGE must be omitted` ).
    cl_abap_unit_assert=>assert_false(
        act = xsdbool( line_exists( names[ name = `ROOT_PROPERTY` ] ) )
        msg = `ROOT_PROPERTY must be omitted` ).
    cl_abap_unit_assert=>assert_false(
        act = xsdbool( line_exists( names[ name = `ROOT_LOCK` ] ) )
        msg = `ROOT_LOCK must be omitted` ).
    cl_abap_unit_assert=>assert_false(
        act = xsdbool( line_exists( names[ name = `ITEM_MESSAGE` ] ) )
        msg = `ITEM_MESSAGE must be omitted` ).
    cl_abap_unit_assert=>assert_false(
        act = xsdbool( line_exists( names[ name = `ITEM_PROPERTY` ] ) )
        msg = `ITEM_PROPERTY must be omitted` ).
  ENDMETHOD.


  METHOD associations_are_qualified.
    " Given the sales-order configuration with navigation and short-text associations
    " When listing selectable associations
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-association ).

    " Then each association is qualified by its source node
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.ITEM` ] ) )
        msg = `ROOT.ITEM must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.ROOT_TEXT` ] ) )
        msg = `ROOT.ROOT_TEXT must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.ROOT_TEXT_IN_LOGON_LANG` ] ) )
        msg = `ROOT.ROOT_TEXT_IN_LOGON_LANG must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ITEM.ITEM_TEXT` ] ) )
        msg = `ITEM.ITEM_TEXT must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ITEM.TO_PARENT` ] ) )
        msg = `ITEM.TO_PARENT must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ITEM.TO_ROOT` ] ) )
        msg = `ITEM.TO_ROOT must be selectable` ).
  ENDMETHOD.


  METHOD associations_have_node_targets.
    " Given the sales-order configuration with root-to-item and item-to-parent navigation
    " When listing selectable associations
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-association ).

    " Then their info identifies the respective target node
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.ITEM` ] ) )
        msg = `ROOT.ITEM must be selectable` ).
    cl_abap_unit_assert=>assert_equals(
        act = names[ name = `ROOT.ITEM` ]-info
        exp = `ITEM` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ITEM.TO_PARENT` ] ) )
        msg = `ITEM.TO_PARENT must be selectable` ).
    cl_abap_unit_assert=>assert_equals(
        act = names[ name = `ITEM.TO_PARENT` ]-info
        exp = `ROOT` ).
  ENDMETHOD.


  METHOD text_assoc_has_parameter_type.
    " Given the parameterized short-text association of ROOT
    " When resolving its metadata from the demo configuration
    DATA(association) = metadata->get_association( node = metadata->get_node( `ROOT` )
                                                   name = `ROOT_TEXT` ).

    " Then its filter type is the configured language structure
    cl_abap_unit_assert=>assert_bound( association-parameter_type ).
    cl_abap_unit_assert=>assert_equals(
        act = association-parameter_type->get_relative_name( )
        exp = `/BOBF/S_DEMO_LANGUAGE_CODE` ).
  ENDMETHOD.


  METHOD item_assoc_has_no_parameters.
    " Given the parameterless composition from ROOT to ITEM
    " When resolving its metadata from the demo configuration
    DATA(association) = metadata->get_association( node = metadata->get_node( `ROOT` )
                                                   name = `ITEM` ).

    " Then no filter type is bound
    cl_abap_unit_assert=>assert_not_bound( association-parameter_type ).
  ENDMETHOD.


  METHOD dependent_assocs_are_listed.
    " Given the sales-order configuration with the root long-text dependent object
    " When listing selectable associations
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-association ).

    " Then its object association targets the dependent root and its content association is qualified
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.ROOT_LONG_TEXT` ] ) )
        msg = `ROOT.ROOT_LONG_TEXT must be selectable` ).
    cl_abap_unit_assert=>assert_equals(
        act = names[ name = `ROOT.ROOT_LONG_TEXT` ]-info
        exp = `ROOT_LONG_TEXT` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT_LONG_TEXT.CONTENT` ] ) )
        msg = `ROOT_LONG_TEXT.CONTENT must be selectable` ).
  ENDMETHOD.


  METHOD cross_bo_targets_name_objects.
    " Given the sales-order configuration with customer and product associations
    " When listing selectable associations
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-association ).

    " Then their info identifies the foreign business object
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.CUSTOMER_ROOT` ] ) )
        msg = `ROOT.CUSTOMER_ROOT must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( names[ name = `ROOT.CUSTOMER_ROOT` ]-info CP '/BOBF/DEMO_CUSTOMER*' )
        msg = `ROOT.CUSTOMER_ROOT must identify /BOBF/DEMO_CUSTOMER` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ITEM.PRODUCT_ROOT` ] ) )
        msg = `ITEM.PRODUCT_ROOT must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( names[ name = `ITEM.PRODUCT_ROOT` ]-info CP '/BOBF/DEMO_PRODUCT*' )
        msg = `ITEM.PRODUCT_ROOT must identify /BOBF/DEMO_PRODUCT` ).
  ENDMETHOD.


  METHOD technical_assocs_are_excluded.
    " Given the sales-order configuration with associations originating at technical nodes
    " When listing selectable associations
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-association ).

    " Then no association originates at a root message, property or lock node
    cl_abap_unit_assert=>assert_not_initial( names ).
    LOOP AT names ASSIGNING FIELD-SYMBOL(<name>).
      cl_abap_unit_assert=>assert_false(
          act = xsdbool( <name>-name CP 'ROOT_MESSAGE.*' )
          msg = |Association { <name>-name } must not originate at ROOT_MESSAGE| ).
      cl_abap_unit_assert=>assert_false(
          act = xsdbool( <name>-name CP 'ROOT_PROPERTY.*' )
          msg = |Association { <name>-name } must not originate at ROOT_PROPERTY| ).
      cl_abap_unit_assert=>assert_false(
          act = xsdbool( <name>-name CP 'ROOT_LOCK.*' )
          msg = |Association { <name>-name } must not originate at ROOT_LOCK| ).
    ENDLOOP.
  ENDMETHOD.


  METHOD alternative_keys_are_qualified.
    " Given the sales-order configuration with the order-id alternative key
    " When listing selectable alternative keys
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-alternative_key ).

    " Then the alternative key is qualified by its node
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.ORDER_ID` ] ) )
        msg = `ROOT.ORDER_ID must be selectable` ).
  ENDMETHOD.


  METHOD deliver_has_parameter_info.
    " Given the sales-order configuration with the parameterized DELIVER action and no result
    " When listing selectable actions
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-action ).

    " Then DELIVER info contains exactly its parameter structure
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.DELIVER` ] ) )
        msg = `ROOT.DELIVER must be selectable` ).
    cl_abap_unit_assert=>assert_equals(
        act = names[ name = `ROOT.DELIVER` ]-info
        exp = `/BOBF/S_DEMO_SALES_ORDER_HDR_D` ).
  ENDMETHOD.


  METHOD archive_has_no_parameter_info.
    " Given the sales-order configuration with the parameterless ARCHIVE action
    " When listing selectable actions
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-action ).

    " Then ARCHIVE remains selectable with empty info
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.ARCHIVE` ] ) )
        msg = `ROOT.ARCHIVE must be selectable` ).
    cl_abap_unit_assert=>assert_initial( names[ name = `ROOT.ARCHIVE` ]-info ).
  ENDMETHOD.


  METHOD queries_are_qualified.
    " Given the sales-order configuration with select-all and element-filter queries
    " When listing selectable queries
    DATA(names) = metadata->get_selectable_names( zcl_bfw_metadata=>selectable_kinds-query ).

    " Then both queries are qualified by the root node
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.SELECT_ALL` ] ) )
        msg = `ROOT.SELECT_ALL must be selectable` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( names[ name = `ROOT.SELECT_BY_ELEMENTS` ] ) )
        msg = `ROOT.SELECT_BY_ELEMENTS must be selectable` ).
  ENDMETHOD.


  METHOD unknown_kind_has_no_names.
    " Given the sales-order configuration and an unsupported selectable kind
    " When listing names for that kind
    DATA(names) = metadata->get_selectable_names( `unknown_kind` ).

    " Then no names are returned
    cl_abap_unit_assert=>assert_initial( names ).
  ENDMETHOD.
ENDCLASS.
