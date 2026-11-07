CLASS ltcl_business_object DEFINITION DEFERRED.
CLASS zcl_bfw_business_object DEFINITION LOCAL FRIENDS ltcl_business_object.

CLASS ltcl_business_object_contracts DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS classifies_interface_methods FOR TESTING.
ENDCLASS.

CLASS ltcl_service_manager DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT
  FRIENDS ltcl_business_object.

  PUBLIC SECTION.
    INTERFACES /bobf/if_tra_service_manager PARTIALLY IMPLEMENTED.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF image_option,
        before_image     TYPE abap_bool,
        invalidate_cache TYPE abap_bool,
      END OF image_option,
      image_options TYPE STANDARD TABLE OF image_option WITH EMPTY KEY.

    TYPES:
      BEGIN OF retrieval,
        node_key             TYPE /bobf/obm_node_key,
        keys                 TYPE /bobf/t_frw_key,
        requested_attributes TYPE /bobf/t_frw_name,
        edit_mode            TYPE string,
        fill_data            TYPE abap_bool,
        before_image         TYPE abap_bool,
        invalidate_cache     TYPE abap_bool,
      END OF retrieval,
      retrieval_entries TYPE STANDARD TABLE OF retrieval WITH EMPTY KEY.

    TYPES:
      BEGIN OF association_call,
        node_key            TYPE /bobf/obm_node_key,
        association_key     TYPE /bobf/obm_assoc_key,
        keys                TYPE /bobf/t_frw_key,
        parameters          TYPE REF TO data,
        filtered_attributes TYPE /bobf/t_frw_name,
        before_image        TYPE abap_bool,
        invalidate_cache    TYPE abap_bool,
      END OF association_call,
      association_entries TYPE STANDARD TABLE OF association_call WITH EMPTY KEY.

    TYPES:
      BEGIN OF action_call,
        action_key TYPE /bobf/act_key,
        keys       TYPE /bobf/t_frw_key,
        parameters TYPE REF TO data,
      END OF action_call,
      action_entries TYPE STANDARD TABLE OF action_call WITH EMPTY KEY.

    TYPES:
      BEGIN OF query_call,
        query_key            TYPE /bobf/obm_query_key,
        filter_keys          TYPE /bobf/t_frw_key,
        selection_parameters TYPE /bobf/t_frw_query_selparam,
        options              TYPE /bobf/s_frw_query_options,
      END OF query_call,
      query_entries TYPE STANDARD TABLE OF query_call WITH EMPTY KEY.

    TYPES order_ids TYPE STANDARD TABLE OF /bobf/s_demo_sales_order_id WITH EMPTY KEY.

    DATA calls TYPE string_table.
    DATA retrievals TYPE retrieval_entries.
    DATA association_calls TYPE association_entries.
    DATA modifications TYPE /bobf/t_frw_modification.
    DATA action_calls TYPE action_entries.
    DATA query_calls TYPE query_entries.
    DATA alternative_node_key TYPE /bobf/obm_node_key.
    DATA alternative_key TYPE /bobf/obm_altkey_key.
    DATA alternative_values TYPE order_ids.
    DATA alternative_options TYPE image_options.

    DATA rows TYPE REF TO data.
    DATA read_failed_keys TYPE /bobf/t_frw_key.
    DATA missing_keys_after_modify TYPE /bobf/t_frw_key.
    DATA read_messages TYPE REF TO /bobf/if_frw_message.
    DATA modify_messages TYPE REF TO /bobf/if_frw_message.
    DATA action_failed_keys TYPE /bobf/t_frw_key.
    DATA failed_action_keys TYPE /bobf/t_frw_key.
    DATA action_messages TYPE REF TO /bobf/if_frw_message.
    DATA key_results TYPE /bobf/t_frw_keyindex.
    DATA query_keys TYPE /bobf/t_frw_key.
    DATA new_key TYPE /bobf/conf_key.
ENDCLASS.

CLASS ltcl_business_object DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF root_projection,
        sales_org TYPE /bobf/s_demo_sales_order_hdr_k-sales_org,
        key       TYPE sysuuid_x16,
        order_id  TYPE /bobf/s_demo_sales_order_hdr_k-order_id,
      END OF root_projection,
      root_projections TYPE STANDARD TABLE OF root_projection WITH EMPTY KEY.

    TYPES:
      BEGIN OF order_projection,
        sales_org TYPE /bobf/s_demo_sales_order_hdr_k-sales_org,
        order_id  TYPE /bobf/s_demo_sales_order_hdr_k-order_id,
      END OF order_projection,
      order_projections TYPE STANDARD TABLE OF order_projection WITH EMPTY KEY.

    TYPES:
      BEGIN OF item_projection,
        key    TYPE sysuuid_x16,
        amount TYPE /bobf/s_demo_sales_order_itm_k-amount,
      END OF item_projection,
      item_projections TYPE STANDARD TABLE OF item_projection WITH EMPTY KEY.

    TYPES:
      BEGIN OF text_creation,
        key        TYPE sysuuid_x16,
        parent_key TYPE sysuuid_x16,
        text       TYPE /bobf/s_demo_short_text_k-text,
      END OF text_creation,
      text_creations TYPE STANDARD TABLE OF text_creation WITH EMPTY KEY.

    TYPES:
      BEGIN OF unknown_component,
        key           TYPE sysuuid_x16,
        unknown_field TYPE string,
      END OF unknown_component,
      unknown_components TYPE STANDARD TABLE OF unknown_component WITH EMPTY KEY.

    TYPES:
      BEGIN OF delivery_parameter,
        item_no TYPE /bobf/s_demo_sales_order_hdr_d-item_no,
      END OF delivery_parameter.

    TYPES:
      BEGIN OF language_filter,
        language TYPE string,
      END OF language_filter,
      BEGIN OF unknown_filter,
        language      TYPE string,
        unknown_field TYPE string,
      END OF unknown_filter.

    TYPES order_ids TYPE STANDARD TABLE OF /bobf/s_demo_sales_order_id WITH EMPTY KEY.
    TYPES long_text_roots TYPE STANDARD TABLE OF /bobf/s_demo_longtext_hdr_k WITH EMPTY KEY.
    TYPES library_rows TYPE STANDARD TABLE OF /bobf/s_conf_lib WITH EMPTY KEY.

    CONSTANTS first_key TYPE sysuuid_x16 VALUE '00000000000000000000000000000001'.
    CONSTANTS second_key TYPE sysuuid_x16 VALUE '00000000000000000000000000000002'.
    CONSTANTS child_key TYPE sysuuid_x16 VALUE '00000000000000000000000000000003'.
    CONSTANTS generated_key TYPE sysuuid_x16 VALUE '00000000000000000000000000000004'.

    CLASS-DATA business_object_key TYPE /bobf/obm_bo_key.
    CLASS-DATA configuration TYPE REF TO /bobf/if_frw_configuration.
    CLASS-DATA library_business_object_key TYPE /bobf/obm_bo_key.
    CLASS-DATA library_configuration TYPE REF TO /bobf/if_frw_configuration.
    CLASS-DATA root_node_key TYPE /bobf/obm_node_key.
    CLASS-DATA item_node_key TYPE /bobf/obm_node_key.
    CLASS-DATA text_node_key TYPE /bobf/obm_node_key.
    CLASS-DATA text_association_key TYPE /bobf/obm_assoc_key.
    CLASS-DATA long_text_node_key TYPE /bobf/obm_node_key.
    CLASS-DATA long_text_association_key TYPE /bobf/obm_assoc_key.

    DATA service_manager TYPE REF TO ltcl_service_manager.
    DATA business_object TYPE REF TO zif_bfw_business_object.
    DATA library_business_object TYPE REF TO zif_bfw_business_object.

    CLASS-METHODS class_setup RAISING cx_static_check.
    METHODS setup.
    METHODS create_messages
      IMPORTING
        key           TYPE sysuuid_x16
        severity      TYPE bapiret2-type DEFAULT 'E'
        is_locked     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE REF TO /bobf/if_frw_message.

    METHODS read_maps_reordered_fields FOR TESTING.
    METHODS read_passes_image_options FOR TESTING.
    METHODS assoc_passes_image_options FOR TESTING.
    METHODS assoc_maps_language_filter FOR TESTING.
    METHODS assoc_uppercases_filter_fields FOR TESTING.
    METHODS assoc_initial_filter_is_absent FOR TESTING.
    METHODS assoc_omitted_filter_is_absent FOR TESTING.
    METHODS assoc_ignores_untyped_filter FOR TESTING.
    METHODS assoc_rejects_unknown_filter FOR TESTING.
    METHODS read_rejects_unknown_field FOR TESTING.
    METHODS empty_read_skips_service FOR TESTING.
    METHODS empty_assoc_skips_service FOR TESTING.
    METHODS empty_delete_skips_service FOR TESTING.
    METHODS read_lock_preserves_row FOR TESTING.
    METHODS root_lock_marks_child_failed FOR TESTING.
    METHODS update_sends_changed_fields FOR TESTING.
    METHODS unchanged_update_skips_modify FOR TESTING.
    METHODS unread_row_is_not_modified FOR TESTING.
    METHODS locked_row_is_not_modified FOR TESTING.
    METHODS create_writes_generated_key FOR TESTING.
    METHODS create_uses_parent_composition FOR TESTING.
    METHODS create_do_uses_object_assoc FOR TESTING.
    METHODS child_without_parent_raises FOR TESTING.
    METHODS create_error_keeps_instance FOR TESTING.
    METHODS create_missing_instance_fails FOR TESTING.
    METHODS delete_existing_instance_fails FOR TESTING.
    METHODS delete_keeps_modify_messages FOR TESTING.
    METHODS update_error_keeps_instance FOR TESTING.
    METHODS execute_maps_action_parameters FOR TESTING.
    METHODS action_merges_failed_keys FOR TESTING.
    METHODS alt_keys_keep_input_indexes FOR TESTING.
    METHODS alt_key_passes_image_options FOR TESTING.
    METHODS query_maps_selection FOR TESTING.
    METHODS query_passes_filter_keys FOR TESTING.
    METHODS query_maps_sorting FOR TESTING.
    METHODS query_maps_row_paging FOR TESTING.
    METHODS query_maps_key_paging FOR TESTING.
    METHODS query_initial_paging_inactive FOR TESTING.
    METHODS query_orders_node_rows FOR TESTING.
    METHODS query_orders_projection_rows FOR TESTING.
    METHODS query_orders_standard_lib_rows FOR TESTING.
    METHODS query_keeps_sorted_lib_rows FOR TESTING.
    METHODS create_locked_parent_fails FOR TESTING.
    METHODS create_missing_parent_fails FOR TESTING.
    METHODS create_locks_same_parent_once FOR TESTING.
    METHODS delete_skips_locked_instance FOR TESTING.
    METHODS delete_skips_missing_instance FOR TESTING.
ENDCLASS.



CLASS ltcl_business_object_contracts IMPLEMENTATION.

  METHOD classifies_interface_methods.
    DATA expected_contract TYPE LINE OF cl_abap_behvdescr=>tt_proc_contract.

    " Given the weak read and modify contracts of the public business object interface
    DATA(expected_contracts) = VALUE cl_abap_behvdescr=>tt_proc_contract(
        ( proc = 'READ'                    contract = cl_abap_behvdescr=>read   severity = cl_abap_behvdescr=>weak )
        ( proc = 'READ_REFERENCE'          contract = cl_abap_behvdescr=>read   severity = cl_abap_behvdescr=>weak )
        ( proc = 'READ_BY_ASSOCIATION'     contract = cl_abap_behvdescr=>read   severity = cl_abap_behvdescr=>weak )
        ( proc = 'CONVERT_ALTERNATIVE_KEY' contract = cl_abap_behvdescr=>read   severity = cl_abap_behvdescr=>weak )
        ( proc = 'QUERY'                   contract = cl_abap_behvdescr=>read   severity = cl_abap_behvdescr=>weak )
        ( proc = 'CREATE'                  contract = cl_abap_behvdescr=>modify severity = cl_abap_behvdescr=>weak )
        ( proc = 'UPDATE'                  contract = cl_abap_behvdescr=>modify severity = cl_abap_behvdescr=>weak )
        ( proc = 'DELETE'                  contract = cl_abap_behvdescr=>modify severity = cl_abap_behvdescr=>weak )
        ( proc = 'EXECUTE_ACTION'          contract = cl_abap_behvdescr=>modify severity = cl_abap_behvdescr=>weak ) ).

    " When inspecting the interface classification
    cl_abap_behvdescr=>get_contracts(
        EXPORTING name      = 'ZIF_BFW_BUSINESS_OBJECT'
                  kind      = 'J'
        IMPORTING contracts = DATA(contracts) ).

    " Then all nine methods have exactly the expected contract and weak severity, in any order
    cl_abap_unit_assert=>assert_equals( act = lines( contracts )
                                        exp = 9 ).
    LOOP AT expected_contracts INTO expected_contract.
      cl_abap_unit_assert=>assert_table_contains(
          line  = expected_contract
          table = contracts
          msg   = expected_contract-proc ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.



CLASS ltcl_service_manager IMPLEMENTATION.

  METHOD /bobf/if_tra_service_manager~retrieve.
    FIELD-SYMBOLS <rows> TYPE INDEX TABLE.

    INSERT `RETRIEVE` INTO TABLE calls.
    INSERT VALUE #( node_key             = iv_node_key
                    keys                 = it_key
                    requested_attributes = it_requested_attributes
                    edit_mode            = iv_edit_mode
                    fill_data            = iv_fill_data
                    before_image         = iv_before_image
                    invalidate_cache     = iv_invalidate_cache ) INTO TABLE retrievals.
    CLEAR et_data.
    IF iv_fill_data = abap_true AND rows IS BOUND.
      ASSIGN rows->* TO <rows>.
      IF sy-subrc <> 0.
        cl_abap_unit_assert=>fail( `The canned response must be an index table` ).
      ENDIF.
      et_data = <rows>.
    ENDIF.
    et_failed_key = read_failed_keys.
    IF modifications IS NOT INITIAL.
      et_failed_key = missing_keys_after_modify.
    ENDIF.
    eo_message = read_messages.
  ENDMETHOD.


  METHOD /bobf/if_tra_service_manager~retrieve_by_association.
    INSERT `RETRIEVE_BY_ASSOCIATION` INTO TABLE calls.
    INSERT VALUE #( node_key            = iv_node_key
                    association_key     = iv_association
                    keys                = it_key
                    parameters          = is_parameters
                    filtered_attributes = it_filtered_attributes
                    before_image        = iv_before_image
                    invalidate_cache    = iv_invalidate_cache ) INTO TABLE association_calls.
    CLEAR: et_data, et_key_link, et_failed_key, eo_message.
  ENDMETHOD.


  METHOD /bobf/if_tra_service_manager~modify.
    INSERT `MODIFY` INTO TABLE calls.
    INSERT LINES OF it_modification INTO TABLE modifications.
    eo_message = modify_messages.
  ENDMETHOD.


  METHOD /bobf/if_tra_service_manager~get_new_key.
    INSERT `GET_NEW_KEY` INTO TABLE calls.
    ev_key = new_key.
  ENDMETHOD.


  METHOD /bobf/if_tra_service_manager~do_action.
    INSERT `DO_ACTION` INTO TABLE calls.
    INSERT VALUE #( action_key = iv_act_key
                    keys       = it_key
                    parameters = is_parameters ) INTO TABLE action_calls.
    CLEAR et_data.
    et_failed_key = action_failed_keys.
    et_failed_action_key = failed_action_keys.
    eo_message = action_messages.
  ENDMETHOD.


  METHOD /bobf/if_tra_service_manager~convert_altern_key.
    INSERT `CONVERT_ALTERN_KEY` INTO TABLE calls.
    alternative_node_key = iv_node_key.
    alternative_key = iv_altkey_key.
    alternative_values = CORRESPONDING #( it_key ).
    INSERT VALUE #( before_image     = iv_before_image
                    invalidate_cache = iv_invalidate_cache ) INTO TABLE alternative_options.
    et_result = key_results.
    CLEAR eo_message.
  ENDMETHOD.


  METHOD /bobf/if_tra_service_manager~query.
    INSERT `QUERY` INTO TABLE calls.
    INSERT VALUE #( query_key            = iv_query_key
                    filter_keys          = it_filter_key
                    selection_parameters = it_selection_parameters
                    options              = is_query_options ) INTO TABLE query_calls.
    et_key = query_keys.
    CLEAR eo_message.
  ENDMETHOD.
ENDCLASS.



CLASS ltcl_business_object IMPLEMENTATION.

  METHOD class_setup.
    business_object_key = /bobf/cl_frw_factory=>query_bo( '/BOBF/DEMO_SALES_ORDER' ).
    cl_abap_unit_assert=>assert_not_initial( business_object_key ).
    configuration = /bobf/cl_frw_factory=>get_configuration( business_object_key ).
    configuration->get_node_tab( IMPORTING et_node = DATA(nodes) ).
    root_node_key = nodes[ node_name = 'ROOT'
                          parent_node_key = VALUE /bobf/obm_node_key( ) ]-node_key.
    item_node_key = nodes[ KEY key2 COMPONENTS node_name = 'ITEM' ]-node_key.
    text_node_key = nodes[ KEY key2 COMPONENTS node_name = 'ROOT_TEXT' ]-node_key.
    configuration->get_assoc_tab( IMPORTING et_assoc = DATA(associations) ).
    DATA(text_association) = associations[ KEY key2 COMPONENTS source_node_key = root_node_key
                                                             assoc_name = 'ROOT_TEXT' ].
    text_association_key = text_association-assoc_key.
    DATA(long_text_association) = associations[ KEY key2 COMPONENTS source_node_key = root_node_key
                                                                  assoc_name = 'ROOT_LONG_TEXT' ].
    long_text_association_key = long_text_association-assoc_key.
    long_text_node_key = long_text_association-target_node_key.

    library_business_object_key = /bobf/cl_frw_factory=>query_bo( '/BOBF/CONF_LIBRARY' ).
    cl_abap_unit_assert=>assert_not_initial( library_business_object_key ).
    library_configuration = /bobf/cl_frw_factory=>get_configuration( library_business_object_key ).
  ENDMETHOD.


  METHOD setup.
    service_manager = NEW #( ).
    service_manager->rows = NEW /bobf/t_demo_sales_order_hdr_k(
        ( key = first_key root_key = first_key order_id = 'Original' sales_org = 'EMEA' amount_curr = 'EUR' ) ).
    service_manager->new_key = generated_key.
    business_object = NEW zcl_bfw_business_object( business_object_key = business_object_key
                                                   service_manager     = service_manager
                                                   configuration       = configuration ).
    library_business_object = NEW zcl_bfw_business_object( business_object_key = library_business_object_key
                                                           service_manager     = service_manager
                                                           configuration       = library_configuration ).
  ENDMETHOD.


  METHOD create_messages.
    result = /bobf/cl_frw_factory=>get_message( ).
    IF is_locked = abap_true.
      result->add_cm( NEW /bobf/cm_frw_lock(
          textid             = /bobf/cm_frw_lock=>retrieve_foreign_lock
          severity           = severity
          symptom            = /bobf/if_frw_message_symptoms=>co_foreign_lock
          ms_origin_location = VALUE #( bo_key = business_object_key node_key = root_node_key key = key )
          mv_user            = 'LOCK_OWNER' ) ).
      RETURN.
    ENDIF.
    result->add_message( is_msg  = VALUE #( msgty = severity msgid = 'ZBFW' msgno = '016' )
                         iv_node = root_node_key
                         iv_key  = key ).
  ENDMETHOD.


  METHOD read_maps_reordered_fields.
    DATA orders TYPE root_projections.

    " Given a projection with a different field order from the configured node
    " When reading the canned root through the engine
    business_object->read( EXPORTING node  = `ROOT`
                                      keys = VALUE #( ( key = first_key ) )
                            IMPORTING rows = orders ).

    " Then values are mapped by name and only business attributes are requested
    cl_abap_unit_assert=>assert_equals(
        act = orders
        exp = VALUE root_projections( ( key = first_key order_id = 'Original' sales_org = 'EMEA' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->retrievals[ 1 ]-node_key
                                        exp = root_node_key ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->retrievals[ 1 ]-keys
                                        exp = VALUE /bobf/t_frw_key( ( key = first_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->retrievals[ 1 ]-requested_attributes
        exp = VALUE /bobf/t_frw_name( ( `SALES_ORG` ) ( `ORDER_ID` ) ) ).
    cl_abap_unit_assert=>assert_false( service_manager->retrievals[ 1 ]-before_image ).
    cl_abap_unit_assert=>assert_false( service_manager->retrievals[ 1 ]-invalidate_cache ).
  ENDMETHOD.


  METHOD read_passes_image_options.
    DATA option TYPE ltcl_service_manager=>image_option.

    " Given each combination of the two independent image options
    DATA(options) = VALUE ltcl_service_manager=>image_options(
        ( )
        ( before_image = abap_true )
        ( invalidate_cache = abap_true )
        ( before_image = abap_true invalidate_cache = abap_true ) ).

    " When reading with each combination
    LOOP AT options INTO option.
      business_object->read( node             = `ROOT`
                             keys             = VALUE #( ( key = first_key ) )
                             before_image     = option-before_image
                             invalidate_cache = option-invalidate_cache ).
    ENDLOOP.

    " Then RETRIEVE receives both options independently and unchanged
    cl_abap_unit_assert=>assert_equals(
        act = CORRESPONDING ltcl_service_manager=>image_options( service_manager->retrievals )
        exp = options ).
  ENDMETHOD.


  METHOD assoc_passes_image_options.
    DATA option TYPE ltcl_service_manager=>image_option.

    " Given each combination of the two independent image options
    DATA(options) = VALUE ltcl_service_manager=>image_options(
        ( )
        ( before_image = abap_true )
        ( invalidate_cache = abap_true )
        ( before_image = abap_true invalidate_cache = abap_true ) ).

    " When navigating with each combination
    LOOP AT options INTO option.
      business_object->read_by_association( node             = `ROOT`
                                            association      = `ITEM`
                                            keys             = VALUE #( ( key = first_key ) )
                                            before_image     = option-before_image
                                            invalidate_cache = option-invalidate_cache ).
    ENDLOOP.

    " Then RETRIEVE_BY_ASSOCIATION receives both options independently and unchanged
    cl_abap_unit_assert=>assert_equals(
        act = CORRESPONDING ltcl_service_manager=>image_options( service_manager->association_calls )
        exp = options ).
  ENDMETHOD.


  METHOD assoc_maps_language_filter.
    " Given a caller-owned filter whose LANGUAGE has a different type from the DDIC component
    DATA(filter) = VALUE language_filter( language = `D` ).

    " When navigating the parameterized short-text association
    business_object->read_by_association( node        = `ROOT`
                                          association = `ROOT_TEXT`
                                          keys        = VALUE #( ( key = first_key ) )
                                          filter      = filter ).

    " Then the named component is mapped into the language structure and filters by default
    DATA(association_call) = service_manager->association_calls[ 1 ].
    cl_abap_unit_assert=>assert_bound( association_call-parameters ).
    DATA(parameter) = CAST /bobf/s_demo_language_code( association_call-parameters ).
    cl_abap_unit_assert=>assert_equals( act = parameter->*
                                        exp = VALUE /bobf/s_demo_language_code( language = 'D' ) ).
    cl_abap_unit_assert=>assert_equals( act = association_call-filtered_attributes
                                        exp = VALUE /bobf/t_frw_name( ( `LANGUAGE` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = association_call-node_key
                                        exp = root_node_key ).
    cl_abap_unit_assert=>assert_equals( act = association_call-association_key
                                        exp = text_association_key ).
    cl_abap_unit_assert=>assert_equals( act = association_call-keys
                                        exp = VALUE /bobf/t_frw_key( ( key = first_key ) ) ).
  ENDMETHOD.


  METHOD assoc_uppercases_filter_fields.
    " Given an initial filter and an explicit component name in mixed case
    DATA filter TYPE language_filter.

    " When explicitly filtering for the initial language value
    business_object->read_by_association( node                = `ROOT`
                                          association         = `ROOT_TEXT`
                                          keys                = VALUE #( ( key = first_key ) )
                                          filter              = filter
                                          filtered_attributes = VALUE #( ( `LaNgUaGe` ) ) ).

    " Then parameters are sent despite their initial value and the component name is upper case
    DATA(association_call) = service_manager->association_calls[ 1 ].
    cl_abap_unit_assert=>assert_bound( association_call-parameters ).
    DATA(parameter) = CAST /bobf/s_demo_language_code( association_call-parameters ).
    cl_abap_unit_assert=>assert_initial( parameter->* ).
    cl_abap_unit_assert=>assert_equals( act = association_call-filtered_attributes
                                        exp = VALUE /bobf/t_frw_name( ( `LANGUAGE` ) ) ).
  ENDMETHOD.


  METHOD assoc_initial_filter_is_absent.
    " Given an initial language filter without an explicit component list
    DATA filter TYPE language_filter.

    " When navigating the parameterized association
    business_object->read_by_association( node        = `ROOT`
                                          association = `ROOT_TEXT`
                                          keys        = VALUE #( ( key = first_key ) )
                                          filter      = filter ).

    " Then no parameters or filtering attributes are sent to BOPF
    cl_abap_unit_assert=>assert_not_bound( service_manager->association_calls[ 1 ]-parameters ).
    cl_abap_unit_assert=>assert_initial( service_manager->association_calls[ 1 ]-filtered_attributes ).
  ENDMETHOD.


  METHOD assoc_omitted_filter_is_absent.
    " Given the parameterized association without any read options
    " When omitting the filter
    business_object->read_by_association( node        = `ROOT`
                                          association = `ROOT_TEXT`
                                          keys        = VALUE #( ( key = first_key ) ) ).

    " Then BOPF receives no parameters and the image options default to false
    DATA(association_call) = service_manager->association_calls[ 1 ].
    cl_abap_unit_assert=>assert_not_bound( association_call-parameters ).
    cl_abap_unit_assert=>assert_initial( association_call-filtered_attributes ).
    cl_abap_unit_assert=>assert_false( association_call-before_image ).
    cl_abap_unit_assert=>assert_false( association_call-invalidate_cache ).
  ENDMETHOD.


  METHOD assoc_ignores_untyped_filter.
    " Given a filter with an unknown component on an association without parameters
    DATA(filter) = VALUE unknown_filter( language = `D` unknown_field = `Ignored` ).

    " When navigating the parameterless item composition
    business_object->read_by_association( node                = `ROOT`
                                          association         = `ITEM`
                                          keys                = VALUE #( ( key = first_key ) )
                                          filter              = filter
                                          filtered_attributes = VALUE #( ( `unknown_field` ) ) ).

    " Then the filter is ignored without validation or parameters being sent
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `RETRIEVE_BY_ASSOCIATION` ) ) ).
    cl_abap_unit_assert=>assert_not_bound( service_manager->association_calls[ 1 ]-parameters ).
    cl_abap_unit_assert=>assert_initial( service_manager->association_calls[ 1 ]-filtered_attributes ).
  ENDMETHOD.


  METHOD assoc_rejects_unknown_filter.
    " Given a non-initial filter with a component absent from the association's parameter structure
    DATA(filter) = VALUE unknown_filter( language = `D` unknown_field = `Unknown` ).

    " When mapping it to the parameterized short-text association
    TRY.
        business_object->read_by_association( node        = `ROOT`
                                              association = `ROOT_TEXT`
                                              keys        = VALUE #( ( key = first_key ) )
                                              filter      = filter ).
      CATCH zcx_bfw_access.
        " Then invalid components raise the public access exception before BOPF is called
        cl_abap_unit_assert=>assert_initial( service_manager->calls ).
        RETURN.
    ENDTRY.
    cl_abap_unit_assert=>fail( `An unknown filter component must raise ZCX_BFW_ACCESS` ).
  ENDMETHOD.


  METHOD read_rejects_unknown_field.
    DATA orders TYPE unknown_components.

    " Given a caller component that does not exist on ROOT
    " When the engine validates the projection
    TRY.
        business_object->read( EXPORTING node  = `ROOT`
                                          keys = VALUE #( ( key = first_key ) )
                                IMPORTING rows = orders ).
      CATCH zcx_bfw_access.
        " Then validation fails before reaching the service manager
        cl_abap_unit_assert=>assert_initial( service_manager->calls ).
        RETURN.
    ENDTRY.
    cl_abap_unit_assert=>fail( `An unknown row component must raise ZCX_BFW_ACCESS` ).
  ENDMETHOD.


  METHOD empty_read_skips_service.
    " Given no requested keys
    " When reading, even an unknown node must not reach BOPF
    business_object->read( EXPORTING node         = `UNKNOWN_NODE`
                                      keys        = VALUE #( )
                                      for_update  = abap_true
                            IMPORTING failed_keys = DATA(failed_keys)
                                      messages    = DATA(messages) ).

    " Then the result is empty and no service is called
    cl_abap_unit_assert=>assert_initial( service_manager->calls ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_initial( messages ).
  ENDMETHOD.


  METHOD empty_assoc_skips_service.
    " Given no source keys
    " When requesting an association without instances
    business_object->read_by_association( node        = `UNKNOWN_NODE`
                                          association = `UNKNOWN_ASSOCIATION`
                                          keys        = VALUE #( ) ).

    " Then no service is called
    cl_abap_unit_assert=>assert_initial( service_manager->calls ).
  ENDMETHOD.


  METHOD empty_delete_skips_service.
    " Given no keys to delete
    " When deleting without instances
    business_object->delete( node  = `UNKNOWN_NODE`
                              keys = VALUE #( ) ).

    " Then no service is called
    cl_abap_unit_assert=>assert_initial( service_manager->calls ).
  ENDMETHOD.


  METHOD read_lock_preserves_row.
    DATA orders TYPE root_projections.

    " Given a FOREIGN_LOCK symptom for the returned root instance
    service_manager->read_messages = create_messages( key       = first_key
                                                      is_locked = abap_true ).

    " When requesting an exclusive read
    business_object->read( EXPORTING node         = `ROOT`
                                      keys        = VALUE #( ( key = first_key ) )
                                      for_update  = abap_true
                            IMPORTING rows        = orders
                                      failed_keys = DATA(failed_keys)
                                      messages    = DATA(messages) ).

    " Then the readable row survives while its key and lock message report failure
    cl_abap_unit_assert=>assert_equals( act = orders[ 1 ]-key
                                        exp = first_key ).
    cl_abap_unit_assert=>assert_equals( act = lines( orders )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = first_key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-key
                                        exp = first_key ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-bapi_return-number
                                        exp = '101' ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->retrievals[ 1 ]-edit_mode
                                        exp = CONV string( /bobf/if_conf_c=>sc_edit_exclusive ) ).
    cl_abap_unit_assert=>assert_true( service_manager->retrievals[ 1 ]-fill_data ).
  ENDMETHOD.


  METHOD root_lock_marks_child_failed.
    DATA items TYPE item_projections.

    " Given an item whose root, rather than the item key, carries the lock symptom
    service_manager->rows = NEW /bobf/t_demo_sales_order_itm_k(
        ( key = child_key parent_key = first_key root_key = first_key amount = 10 ) ).
    service_manager->read_messages = create_messages( key       = first_key
                                                      is_locked = abap_true ).

    " When reading the child for update
    business_object->read( EXPORTING node         = `ITEM`
                                      keys        = VALUE #( ( key = child_key ) )
                                      for_update  = abap_true
                            IMPORTING rows        = items
                                      failed_keys = DATA(failed_keys)
                                      messages    = DATA(messages) ).

    " Then the child's key fails while its row and the root-origin message remain
    cl_abap_unit_assert=>assert_equals( act = items[ 1 ]-key
                                        exp = child_key ).
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = child_key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-key
                                        exp = first_key ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->retrievals[ 1 ]-node_key
                                        exp = item_node_key ).
  ENDMETHOD.


  METHOD update_sends_changed_fields.
    " Given one changed attribute and an unchanged attribute in the caller's projection
    DATA(changes) = VALUE root_projections( ( key = first_key order_id = 'Changed' sales_org = 'EMEA' ) ).

    " When updating through the field comparison
    business_object->update( node  = `ROOT`
                              rows = changes ).

    " Then only ORDER_ID is marked changed and fields outside the projection survive
    cl_abap_unit_assert=>assert_equals( act = lines( service_manager->modifications )
                                        exp = 1 ).
    DATA(modification) = service_manager->modifications[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = modification-changed_fields
                                        exp = VALUE /bobf/t_frw_name( ( `ORDER_ID` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = modification-change_mode
                                        exp = /bobf/if_frw_c=>sc_modify_update ).
    DATA(order) = CAST /bobf/s_demo_sales_order_hdr_k( modification-data ).
    cl_abap_unit_assert=>assert_equals( act = order->order_id
                                        exp = 'Changed' ).
    cl_abap_unit_assert=>assert_equals( act = order->amount_curr
                                        exp = 'EUR' ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `RETRIEVE` ) ( `MODIFY` ) ) ).
  ENDMETHOD.


  METHOD unchanged_update_skips_modify.
    " Given a projection equal to the canned current state
    DATA(changes) = VALUE root_projections( ( key = first_key order_id = 'Original' sales_org = 'EMEA' ) ).

    " When updating it
    business_object->update( node  = `ROOT`
                              rows = changes ).

    " Then comparison reads the row but sends no modification
    cl_abap_unit_assert=>assert_initial( service_manager->modifications ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `RETRIEVE` ) ) ).
  ENDMETHOD.


  METHOD unread_row_is_not_modified.
    " Given a missing second row alongside a readable row
    service_manager->read_failed_keys = VALUE #( ( key = second_key ) ).
    DATA(changes) = VALUE root_projections( ( key = first_key order_id = 'Changed' sales_org = 'EMEA' )
                                           ( key = second_key order_id = 'Missing' sales_org = 'EMEA' ) ).

    " When updating both requested rows
    business_object->update( EXPORTING node         = `ROOT`
                                        rows        = changes
                              IMPORTING failed_keys = DATA(failed_keys) ).

    " Then only the readable row is modified and the missing key stays failed
    cl_abap_unit_assert=>assert_equals( act = lines( service_manager->modifications )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->modifications[ 1 ]-key
                                        exp = first_key ).
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = second_key ) ) ).
  ENDMETHOD.


  METHOD locked_row_is_not_modified.
    " Given a returned row that cannot be locked
    service_manager->read_messages = create_messages( key       = first_key
                                                      is_locked = abap_true ).
    DATA(changes) = VALUE root_projections( ( key = first_key order_id = 'Changed' sales_org = 'EMEA' ) ).

    " When updating the row
    business_object->update( EXPORTING node         = `ROOT`
                                        rows        = changes
                              IMPORTING failed_keys = DATA(failed_keys) ).

    " Then its data never reaches MODIFY
    cl_abap_unit_assert=>assert_initial( service_manager->modifications ).
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = first_key ) ) ).
  ENDMETHOD.


  METHOD create_writes_generated_key.
    " Given a new root with an initial KEY
    DATA(orders) = VALUE root_projections( ( order_id = 'New' sales_org = 'EMEA' ) ).

    " When creating it through the engine
    business_object->create( EXPORTING node         = `ROOT`
                              IMPORTING failed_keys = DATA(failed_keys)
                              CHANGING  rows        = orders ).

    " Then the service manager's generated key is written into the caller and modification
    cl_abap_unit_assert=>assert_equals( act = orders[ 1 ]-key
                                        exp = generated_key ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->modifications[ 1 ]-key
                                        exp = generated_key ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `GET_NEW_KEY` ) ( `MODIFY` ) ( `RETRIEVE` ) ) ).
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->retrievals[ 1 ]-keys
                                        exp = VALUE /bobf/t_frw_key( ( key = generated_key ) ) ).
    cl_abap_unit_assert=>assert_false( service_manager->retrievals[ 1 ]-fill_data ).
  ENDMETHOD.


  METHOD create_uses_parent_composition.
    " Given a child projection with an explicit parent and key
    DATA(texts) = VALUE text_creations( ( key = child_key parent_key = first_key text = 'Child text' ) ).

    " When creating it under ROOT_TEXT
    business_object->create( EXPORTING node = `ROOT_TEXT`
                              CHANGING rows = texts ).

    " Then the modification uses its parent and the configured composition
    DATA(modification) = service_manager->modifications[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = modification-node
                                        exp = text_node_key ).
    cl_abap_unit_assert=>assert_equals( act = modification-source_node
                                        exp = root_node_key ).
    cl_abap_unit_assert=>assert_equals( act = modification-source_key
                                        exp = first_key ).
    cl_abap_unit_assert=>assert_equals( act = modification-association
                                        exp = text_association_key ).
    cl_abap_unit_assert=>assert_equals( act = modification-change_mode
                                        exp = /bobf/if_frw_c=>sc_modify_create ).
    DATA(text) = CAST /bobf/s_demo_short_text_k( modification-data ).
    cl_abap_unit_assert=>assert_equals( act = text->text
                                        exp = 'Child text' ).
  ENDMETHOD.


  METHOD create_do_uses_object_assoc.
    " Given a DO-root row, without invoking the demo BO's determinations
    DATA(roots) = VALUE long_text_roots( ( key = child_key parent_key = first_key ) ).

    " When creating the qualified dependent root through the double
    business_object->create( EXPORTING node = `ROOT_LONG_TEXT`
                              CHANGING rows = roots ).

    " Then the host's object association supplies the creation context
    DATA(modification) = service_manager->modifications[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = modification-node
                                        exp = long_text_node_key ).
    cl_abap_unit_assert=>assert_equals( act = modification-association
                                        exp = long_text_association_key ).
    cl_abap_unit_assert=>assert_equals( act = modification-source_node
                                        exp = root_node_key ).
    cl_abap_unit_assert=>assert_equals( act = modification-source_key
                                        exp = first_key ).
  ENDMETHOD.


  METHOD child_without_parent_raises.
    " Given an ITEM projection that lacks PARENT_KEY
    DATA(items) = VALUE item_projections( ( key = child_key amount = 10 ) ).

    " When creating a non-root node without its parent component
    TRY.
        business_object->create( EXPORTING node = `ITEM`
                                  CHANGING rows = items ).
      CATCH zcx_bfw_access.
        " Then the engine refuses the row before any service call
        cl_abap_unit_assert=>assert_initial( service_manager->calls ).
        RETURN.
    ENDTRY.
    cl_abap_unit_assert=>fail( `A child row without PARENT_KEY must raise ZCX_BFW_ACCESS` ).
  ENDMETHOD.


  METHOD create_error_keeps_instance.
    " Given a new root that BOPF keeps in the buffer despite a consistency error
    DATA(orders) = VALUE root_projections( ( key = second_key order_id = 'New' sales_org = 'EMEA' ) ).
    service_manager->modify_messages = create_messages( second_key ).

    " When creating it through the engine
    business_object->create( EXPORTING node         = `ROOT`
                              IMPORTING failed_keys = DATA(failed_keys)
                                        messages    = DATA(messages)
                              CHANGING  rows        = orders ).

    " Then the existing instance succeeds and its error remains available
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = messages
                                        exp = NEW zcl_bfw_message_converter( )->convert(
                                            bopf_messages       = service_manager->modify_messages
                                            business_object_key = business_object_key ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-severity
                                        exp = 'E' ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-key
                                        exp = second_key ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `MODIFY` ) ( `RETRIEVE` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->retrievals
        exp = VALUE ltcl_service_manager=>retrieval_entries(
            ( node_key  = root_node_key
              keys      = VALUE #( ( key = second_key ) )
              edit_mode = CONV string( /bobf/if_conf_c=>sc_edit_read_only )
              fill_data = abap_false ) ) ).
  ENDMETHOD.


  METHOD create_missing_instance_fails.
    " Given two creates, one of which BOPF silently drops from the buffer
    DATA(orders) = VALUE root_projections( ( key = first_key order_id = 'Kept' sales_org = 'EMEA' )
                                          ( key = second_key order_id = 'Dropped' sales_org = 'EMEA' ) ).
    service_manager->missing_keys_after_modify = VALUE #( ( key = second_key ) ).

    " When creating both roots
    business_object->create( EXPORTING node         = `ROOT`
                              IMPORTING failed_keys = DATA(failed_keys)
                                        messages    = DATA(messages)
                              CHANGING  rows        = orders ).

    " Then only the instance missing after MODIFY fails, even without an error message
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = second_key ) ) ).
    cl_abap_unit_assert=>assert_initial( messages ).
    cl_abap_unit_assert=>assert_equals( act = lines( service_manager->modifications )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `MODIFY` ) ( `RETRIEVE` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->retrievals[ 1 ]-keys
        exp = VALUE /bobf/t_frw_key( ( key = first_key ) ( key = second_key ) ) ).
    cl_abap_unit_assert=>assert_false( service_manager->retrievals[ 1 ]-fill_data ).
  ENDMETHOD.


  METHOD delete_existing_instance_fails.
    " Given two unlocked roots, one of which BOPF keeps after deletion without an error message
    service_manager->rows = NEW /bobf/t_demo_sales_order_hdr_k(
        ( key = first_key root_key = first_key )
        ( key = second_key root_key = second_key ) ).
    service_manager->missing_keys_after_modify = VALUE #( ( key = second_key ) ).

    " When deleting both requested roots
    business_object->delete( EXPORTING node         = `ROOT`
                                        keys        = VALUE #( ( key = first_key ) ( key = second_key ) )
                              IMPORTING failed_keys = DATA(failed_keys)
                                        messages    = DATA(messages) ).

    " Then only the instance that still exists fails
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = first_key ) ) ).
    cl_abap_unit_assert=>assert_initial( messages ).
    cl_abap_unit_assert=>assert_equals( act = lines( service_manager->modifications )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->calls
        exp = VALUE string_table( ( `RETRIEVE` ) ( `MODIFY` ) ( `RETRIEVE` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->retrievals[ 2 ]
        exp = VALUE ltcl_service_manager=>retrieval(
            node_key  = root_node_key
            keys      = VALUE #( ( key = first_key ) ( key = second_key ) )
            edit_mode = CONV string( /bobf/if_conf_c=>sc_edit_read_only )
            fill_data = abap_false ) ).
  ENDMETHOD.


  METHOD delete_keeps_modify_messages.
    " Given duplicate errors for a requested key, a warning and an unrelated error
    service_manager->rows = NEW /bobf/t_demo_sales_order_hdr_k(
        ( key = first_key root_key = first_key )
        ( key = second_key root_key = second_key ) ).
    service_manager->missing_keys_after_modify = VALUE #( ( key = first_key ) ( key = second_key ) ).
    service_manager->modify_messages = create_messages( first_key ).
    service_manager->modify_messages->add( create_messages( key      = first_key
                                                            severity = 'A' ) ).
    service_manager->modify_messages->add( create_messages( key      = second_key
                                                            severity = 'W' ) ).
    service_manager->modify_messages->add( create_messages( child_key ) ).

    " When deleting two requested instances
    business_object->delete( EXPORTING node         = `ROOT`
                                        keys        = VALUE #( ( key = first_key ) ( key = second_key ) )
                              IMPORTING failed_keys = DATA(failed_keys)
                                        messages    = DATA(messages) ).

    " Then both deleted instances succeed and all messages remain available
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->modifications[ 1 ]-change_mode
                                        exp = /bobf/if_frw_c=>sc_modify_delete ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 4 ).
    cl_abap_unit_assert=>assert_equals( act = messages
                                        exp = NEW zcl_bfw_message_converter( )->convert(
                                            bopf_messages       = service_manager->modify_messages
                                            business_object_key = business_object_key ) ).
  ENDMETHOD.


  METHOD update_error_keeps_instance.
    " Given an unlocked root whose update reports a consistency error on its key
    DATA(changes) = VALUE root_projections( ( key = first_key order_id = 'Changed' sales_org = 'EMEA' ) ).
    service_manager->modify_messages = create_messages( first_key ).

    " When updating the root
    business_object->update( EXPORTING node         = `ROOT`
                                        rows        = changes
                              IMPORTING failed_keys = DATA(failed_keys)
                                        messages    = DATA(messages) ).

    " Then the modified instance succeeds and its error remains available
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `RETRIEVE` ) ( `MODIFY` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->modifications[ 1 ]-key
                                        exp = first_key ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->modifications[ 1 ]-change_mode
                                        exp = /bobf/if_frw_c=>sc_modify_update ).
    cl_abap_unit_assert=>assert_equals( act = messages
                                        exp = NEW zcl_bfw_message_converter( )->convert(
                                            bopf_messages       = service_manager->modify_messages
                                            business_object_key = business_object_key ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-severity
                                        exp = 'E' ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-key
                                        exp = first_key ).
  ENDMETHOD.


  METHOD execute_maps_action_parameters.
    " Given the caller's own parameter structure instead of the configured DDIC type
    DATA(parameters) = VALUE delivery_parameter( item_no = 10 ).

    " When executing DELIVER through its configured name
    business_object->execute_action( node        = `ROOT`
                                      action     = `DELIVER`
                                      keys       = VALUE #( ( key = first_key ) )
                                      parameters = parameters ).

    " Then the double receives the resolved action and parameters mapped into its DDIC type
    DATA(action_call) = service_manager->action_calls[ 1 ].
    DATA(expected_action_key) = configuration->query_action( iv_node_key = root_node_key
                                                             iv_act_name = 'DELIVER' ).
    cl_abap_unit_assert=>assert_equals( act = action_call-action_key
                                        exp = expected_action_key ).
    cl_abap_unit_assert=>assert_equals( act = action_call-keys
                                        exp = VALUE /bobf/t_frw_key( ( key = first_key ) ) ).
    DATA(delivery) = CAST /bobf/s_demo_sales_order_hdr_d( action_call-parameters ).
    cl_abap_unit_assert=>assert_equals( act = delivery->*
                                        exp = VALUE /bobf/s_demo_sales_order_hdr_d( item_no = 10 ) ).
  ENDMETHOD.


  METHOD action_merges_failed_keys.
    " Given failures in both BOPF failure tables, including a duplicate key
    service_manager->action_failed_keys = VALUE #( ( key = first_key ) ).
    service_manager->failed_action_keys = VALUE #( ( key = second_key ) ( key = first_key ) ).
    service_manager->action_messages = create_messages( second_key ).

    " When executing the parameterless action
    business_object->execute_action(
        EXPORTING node        = `ROOT`
                  action      = `ARCHIVE`
                  keys        = VALUE #( ( key = first_key ) ( key = second_key ) )
        IMPORTING failed_keys = DATA(failed_keys)
                  messages    = DATA(messages) ).

    " Then both failure sources contribute to one unique key list
    cl_abap_unit_assert=>assert_equals(
        act = failed_keys
        exp = VALUE zif_bfw_business_object=>keys( ( key = first_key ) ( key = second_key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-key
                                        exp = second_key ).
  ENDMETHOD.


  METHOD alt_keys_keep_input_indexes.
    " Given missing, nonunique and repeated alternative-key results
    DATA(values) = VALUE order_ids( ( order_id = 'Missing' ) ( order_id = 'Nonunique' ) ( order_id = 'Repeated' ) ).
    service_manager->key_results = VALUE #( ( index = 1 )
                                            ( index = 2 key = second_key )
                                            ( index = 2 key = first_key )
                                            ( index = 3 key = second_key ) ).

    " When converting without requesting rows
    business_object->convert_alternative_key(
        EXPORTING node            = `ROOT`
                  alternative_key = `ORDER_ID`
                  values          = values
        IMPORTING keys            = DATA(keys)
                  key_indexes     = DATA(key_indexes) ).

    " Then found indexes keep their positions while KEYS contains each found key once
    cl_abap_unit_assert=>assert_equals(
        act = key_indexes
        exp = VALUE zif_bfw_business_object=>key_indexes( ( index = 2 key = first_key )
                                                         ( index = 2 key = second_key )
                                                         ( index = 3 key = second_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = keys
        exp = VALUE zif_bfw_business_object=>keys( ( key = first_key ) ( key = second_key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->alternative_node_key
                                        exp = root_node_key ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->alternative_key
        exp = configuration->query_altkey( iv_node_key = root_node_key iv_altkey_name = 'ORDER_ID' ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->alternative_values
                                        exp = values ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->alternative_options
                                        exp = VALUE ltcl_service_manager=>image_options( ( ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `CONVERT_ALTERN_KEY` ) ) ).
  ENDMETHOD.


  METHOD alt_key_passes_image_options.
    DATA orders TYPE root_projections.
    DATA option TYPE ltcl_service_manager=>image_option.

    " Given a successful conversion and each combination of the independent image options
    service_manager->key_results = VALUE #( ( index = 1 key = first_key ) ).
    DATA(options) = VALUE ltcl_service_manager=>image_options(
        ( )
        ( before_image = abap_true )
        ( invalidate_cache = abap_true )
        ( before_image = abap_true invalidate_cache = abap_true ) ).

    " When converting and requesting rows for each combination
    LOOP AT options INTO option.
      business_object->convert_alternative_key(
          EXPORTING node             = `ROOT`
                    alternative_key  = `ORDER_ID`
                    values           = VALUE order_ids( ( order_id = 'Original' ) )
                    before_image     = option-before_image
                    invalidate_cache = option-invalidate_cache
          IMPORTING rows             = orders ).
    ENDLOOP.

    " Then both the conversion and its follow-up RETRIEVE receive the same options
    cl_abap_unit_assert=>assert_equals( act = service_manager->alternative_options
                                        exp = options ).
    cl_abap_unit_assert=>assert_equals(
        act = CORRESPONDING ltcl_service_manager=>image_options( service_manager->retrievals )
        exp = options ).
    cl_abap_unit_assert=>assert_equals(
        act = orders
        exp = VALUE root_projections( ( key = first_key order_id = 'Original' sales_org = 'EMEA' ) ) ).
  ENDMETHOD.


  METHOD query_maps_selection.
    " Given ranges that exercise every selection component, including exclusion and HIGH
    DATA(selections) = VALUE zif_bfw_business_object=>selection_parameters(
        ( attribute_name = `ORDER_ID` sign = 'I' option = 'BT' low = `A` high = `Z` )
        ( attribute_name = `SALES_ORG` sign = 'E' option = 'EQ' low = `APJ` ) ).
    service_manager->query_keys = VALUE #( ( key = second_key ) ).

    " When querying with a result limit and without requesting rows
    business_object->query( EXPORTING node                  = `ROOT`
                                       query                = `SELECT_BY_ELEMENTS`
                                       selection_parameters = selections
                                       maximum_rows         = 7
                             IMPORTING keys                 = DATA(keys) ).

    " Then selection values and limit reach BOPF unchanged and no follow-up read occurs
    DATA(query_call) = service_manager->query_calls[ 1 ].
    cl_abap_unit_assert=>assert_equals(
        act = query_call-selection_parameters
        exp = VALUE /bobf/t_frw_query_selparam(
            ( attribute_name = 'ORDER_ID' sign = 'I' option = 'BT' low = 'A' high = 'Z' )
            ( attribute_name = 'SALES_ORG' sign = 'E' option = 'EQ' low = 'APJ' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = query_call-options-maximum_rows
                                        exp = 7 ).
    cl_abap_unit_assert=>assert_initial( query_call-filter_keys ).
    cl_abap_unit_assert=>assert_initial( query_call-options-sorting_options ).
    cl_abap_unit_assert=>assert_initial( query_call-options-paging_options ).
    cl_abap_unit_assert=>assert_equals(
        act = query_call-query_key
        exp = configuration->query_query( iv_node_key = root_node_key iv_query_name = 'SELECT_BY_ELEMENTS' ) ).
    cl_abap_unit_assert=>assert_equals( act = keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = second_key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `QUERY` ) ) ).
  ENDMETHOD.


  METHOD query_passes_filter_keys.
    " Given filter keys in a deliberate order
    DATA(filter_keys) = VALUE zif_bfw_business_object=>keys( ( key = second_key ) ( key = first_key ) ).

    " When restricting a root query by those keys
    business_object->query( node        = `ROOT`
                            query       = `SELECT_BY_ELEMENTS`
                            filter_keys = filter_keys ).

    " Then the full restriction reaches IT_FILTER_KEY unchanged
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->query_calls[ 1 ]-filter_keys
        exp = VALUE /bobf/t_frw_key( ( key = second_key ) ( key = first_key ) ) ).
  ENDMETHOD.


  METHOD query_maps_sorting.
    " Given one descending criterion and one ascending criterion with lower and mixed-case names
    DATA(sorting) = VALUE zif_bfw_business_object=>sorting(
        ( attribute_name = `order_id` descending = abap_true )
        ( attribute_name = `sAlEs_OrG` ) ).

    " When querying with that sort order
    business_object->query( node    = `ROOT`
                            query   = `SELECT_BY_ELEMENTS`
                            sorting = sorting ).

    " Then attribute names are upper case, criterion order is kept and DESCENDING becomes NOT ASCENDING
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->query_calls[ 1 ]-options-sorting_options
        exp = VALUE /bobf/t_frw_query_sorting( ( attribute_name = 'ORDER_ID' ascending = abap_false )
                                              ( attribute_name = 'SALES_ORG' ascending = abap_true ) ) ).
  ENDMETHOD.


  METHOD query_maps_row_paging.
    " Given a page starting at row two with a page size of one
    " When requesting that page
    business_object->query( node         = `ROOT`
                            query        = `SELECT_BY_ELEMENTS`
                            maximum_rows = 1
                            paging       = VALUE #( start_row = 2 ) ).

    " Then paging is active, START_ROW is kept and MAXIMUM_ROWS carries the page size
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->query_calls[ 1 ]-options
        exp = VALUE /bobf/s_frw_query_options(
            maximum_rows   = 1
            paging_options = VALUE #( paging_active = abap_true start_row = 2 ) ) ).
  ENDMETHOD.


  METHOD query_maps_key_paging.
    " Given the last key of the preceding page
    " When requesting the next page using START_KEY
    business_object->query( node         = `ROOT`
                            query        = `SELECT_BY_ELEMENTS`
                            maximum_rows = 3
                            paging       = VALUE #( start_key = second_key ) ).

    " Then START_KEY alone activates paging and the row offset stays initial
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->query_calls[ 1 ]-options
        exp = VALUE /bobf/s_frw_query_options(
            maximum_rows   = 3
            paging_options = VALUE #( paging_active = abap_true start_key = second_key ) ) ).
  ENDMETHOD.


  METHOD query_initial_paging_inactive.
    " Given an explicitly supplied but initial page
    " When querying without any limit or sorting
    business_object->query( node   = `ROOT`
                            query  = `SELECT_ALL`
                            paging = VALUE #( ) ).

    " Then paging stays inactive and the query options retain their defaults
    cl_abap_unit_assert=>assert_initial( service_manager->query_calls[ 1 ]-options ).
    cl_abap_unit_assert=>assert_initial( service_manager->query_calls[ 1 ]-filter_keys ).
  ENDMETHOD.


  METHOD query_orders_node_rows.
    DATA orders TYPE /bobf/t_demo_sales_order_hdr_k.

    " Given query keys in the reverse order of the retrieved node rows
    service_manager->query_keys = VALUE #( ( key = second_key ) ( key = first_key ) ).
    service_manager->rows = NEW /bobf/t_demo_sales_order_hdr_k(
        ( key = first_key order_id = 'First' sales_org = 'EMEA' )
        ( key = second_key order_id = 'Second' sales_org = 'APJ' ) ).

    " When querying into the configured node table type
    business_object->query( EXPORTING node  = `ROOT`
                                      query = `SELECT_ALL`
                            IMPORTING keys  = DATA(keys)
                                      rows  = orders ).

    " Then both keys and full node rows follow query order rather than retrieval order
    cl_abap_unit_assert=>assert_equals(
        act = keys
        exp = VALUE zif_bfw_business_object=>keys( ( key = second_key ) ( key = first_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = orders
        exp = VALUE /bobf/t_demo_sales_order_hdr_k(
            ( key = second_key order_id = 'Second' sales_org = 'APJ' )
            ( key = first_key order_id = 'First' sales_org = 'EMEA' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `QUERY` ) ( `RETRIEVE` ) ) ).
  ENDMETHOD.


  METHOD query_orders_projection_rows.
    DATA orders TYPE order_projections.

    " Given reversed retrieval order and a smaller caller structure without KEY
    service_manager->query_keys = VALUE #( ( key = second_key ) ( key = first_key ) ).
    service_manager->rows = NEW /bobf/t_demo_sales_order_hdr_k(
        ( key = first_key order_id = 'First' sales_org = 'EMEA' )
        ( key = second_key order_id = 'Second' sales_org = 'APJ' ) ).

    " When querying into the projection
    business_object->query( EXPORTING node  = `ROOT`
                                      query = `SELECT_ALL`
                            IMPORTING keys  = DATA(keys)
                                      rows  = orders ).

    " Then mapping the projection preserves the order defined by the query keys
    cl_abap_unit_assert=>assert_equals(
        act = keys
        exp = VALUE zif_bfw_business_object=>keys( ( key = second_key ) ( key = first_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = orders
        exp = VALUE order_projections( ( order_id = 'Second' sales_org = 'APJ' )
                                       ( order_id = 'First' sales_org = 'EMEA' ) ) ).
  ENDMETHOD.


  METHOD query_orders_standard_lib_rows.
    DATA libraries TYPE library_rows.

    " Given a sorted node table and query keys in the reverse order of its retrieved rows
    service_manager->query_keys = VALUE #( ( key = second_key ) ( key = first_key ) ).
    service_manager->rows = NEW /bobf/t_conf_lib(
        ( key = first_key root_key = first_key lib_name = 'First' )
        ( key = second_key root_key = second_key lib_name = 'Second' ) ).

    " When querying the library root into a standard table of the node's line type
    library_business_object->query( EXPORTING node  = `ROOT`
                                              query = `SELECT_ALL`
                                    IMPORTING keys  = DATA(keys)
                                              rows  = libraries ).

    " Then the standard rows and keys follow query order despite the sorted node table type
    cl_abap_unit_assert=>assert_equals(
        act = keys
        exp = VALUE zif_bfw_business_object=>keys( ( key = second_key ) ( key = first_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = libraries
        exp = VALUE library_rows(
            ( key = second_key root_key = second_key lib_name = 'Second' )
            ( key = first_key root_key = first_key lib_name = 'First' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `QUERY` ) ( `RETRIEVE` ) ) ).
  ENDMETHOD.


  METHOD query_keeps_sorted_lib_rows.
    DATA libraries TYPE /bobf/t_conf_lib.

    " Given a sorted node table and query keys in the reverse order of its retrieved rows
    service_manager->query_keys = VALUE #( ( key = second_key ) ( key = first_key ) ).
    service_manager->rows = NEW /bobf/t_conf_lib(
        ( key = first_key root_key = first_key lib_name = 'First' )
        ( key = second_key root_key = second_key lib_name = 'Second' ) ).

    " When querying the library root into its sorted node table type
    library_business_object->query( EXPORTING node  = `ROOT`
                                              query = `SELECT_ALL`
                                    IMPORTING keys  = DATA(keys)
                                              rows  = libraries ).

    " Then rows keep their table key order while keys retain query order
    cl_abap_unit_assert=>assert_equals(
        act = keys
        exp = VALUE zif_bfw_business_object=>keys( ( key = second_key ) ( key = first_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = CORRESPONDING library_rows( libraries )
        exp = VALUE library_rows(
            ( key = first_key root_key = first_key lib_name = 'First' )
            ( key = second_key root_key = second_key lib_name = 'Second' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `QUERY` ) ( `RETRIEVE` ) ) ).
  ENDMETHOD.


  METHOD create_locked_parent_fails.
    " Given a new child whose parent reports a FOREIGN_LOCK warning
    DATA(texts) = VALUE text_creations( ( key = child_key parent_key = first_key text = 'Child text' ) ).
    service_manager->read_messages = create_messages( key       = first_key
                                                      severity  = 'W'
                                                      is_locked = abap_true ).

    " When creating the child under ROOT_TEXT
    business_object->create( EXPORTING node         = `ROOT_TEXT`
                              IMPORTING failed_keys = DATA(failed_keys)
                                        messages    = DATA(messages)
                              CHANGING  rows        = texts ).

    " Then the child fails, the parent's lock message is returned and MODIFY is skipped
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = child_key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-key
                                        exp = first_key ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-severity
                                        exp = 'W' ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-bapi_return-number
                                        exp = '101' ).
    cl_abap_unit_assert=>assert_initial( service_manager->modifications ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `RETRIEVE` ) ) ).
  ENDMETHOD.


  METHOD create_missing_parent_fails.
    " Given a new child whose parent is absent from the retrieve result
    DATA(texts) = VALUE text_creations( ( key = child_key parent_key = first_key text = 'Child text' ) ).
    CLEAR service_manager->rows.
    service_manager->read_failed_keys = VALUE #( ( key = first_key ) ).

    " When creating the child under ROOT_TEXT
    business_object->create( EXPORTING node         = `ROOT_TEXT`
                              IMPORTING failed_keys = DATA(failed_keys)
                              CHANGING  rows        = texts ).

    " Then the child key fails and no modification reaches the service manager
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = child_key ) ) ).
    cl_abap_unit_assert=>assert_initial( service_manager->modifications ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->calls
                                        exp = VALUE string_table( ( `RETRIEVE` ) ) ).
  ENDMETHOD.


  METHOD create_locks_same_parent_once.
    DATA modification TYPE LINE OF /bobf/t_frw_modification.
    DATA text TYPE REF TO /bobf/s_demo_short_text_k.

    " Given two children sharing one parent and nonblocking messages from both phases
    DATA(texts) = VALUE text_creations( ( key = child_key parent_key = first_key text = 'First text' )
                                        ( key = second_key parent_key = first_key text = 'Second text' ) ).
    service_manager->read_messages = create_messages( key      = first_key
                                                      severity = 'W' ).
    service_manager->modify_messages = create_messages( key      = child_key
                                                        severity = 'W' ).

    " When creating both children under ROOT_TEXT
    business_object->create( EXPORTING node         = `ROOT_TEXT`
                              IMPORTING failed_keys = DATA(failed_keys)
                                        messages    = DATA(messages)
                              CHANGING  rows        = texts ).

    " Then the parent is retrieved once with one key before both rows reach MODIFY
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->calls
        exp = VALUE string_table( ( `RETRIEVE` ) ( `MODIFY` ) ( `RETRIEVE` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( service_manager->retrievals )
                                        exp = 2 ).
    DATA(retrieval) = service_manager->retrievals[ 1 ].
    cl_abap_unit_assert=>assert_equals( act = retrieval-node_key
                                        exp = root_node_key ).
    cl_abap_unit_assert=>assert_equals( act = retrieval-edit_mode
                                        exp = CONV string( /bobf/if_conf_c=>sc_edit_exclusive ) ).
    cl_abap_unit_assert=>assert_equals( act = retrieval-keys
                                        exp = VALUE /bobf/t_frw_key( ( key = first_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->retrievals[ 2 ]
        exp = VALUE ltcl_service_manager=>retrieval(
            node_key  = text_node_key
            keys      = VALUE #( ( key = child_key ) ( key = second_key ) )
            edit_mode = CONV string( /bobf/if_conf_c=>sc_edit_read_only )
            fill_data = abap_false ) ).
    cl_abap_unit_assert=>assert_equals(
        act = CORRESPONDING zif_bfw_business_object=>keys( service_manager->modifications )
        exp = VALUE zif_bfw_business_object=>keys( ( key = child_key ) ( key = second_key ) ) ).
    LOOP AT service_manager->modifications INTO modification.
      cl_abap_unit_assert=>assert_equals( act = modification-node
                                          exp = text_node_key ).
      cl_abap_unit_assert=>assert_equals( act = modification-change_mode
                                          exp = /bobf/if_frw_c=>sc_modify_create ).
      cl_abap_unit_assert=>assert_equals( act = modification-source_key
                                          exp = first_key ).
      text = CAST /bobf/s_demo_short_text_k( modification-data ).
      cl_abap_unit_assert=>assert_equals( act = text->key
                                          exp = modification-key ).
      cl_abap_unit_assert=>assert_equals( act = text->text
                                          exp = texts[ key = modification-key ]-text ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_initial( failed_keys ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-key
                                        exp = first_key ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 2 ]-key
                                        exp = child_key ).
  ENDMETHOD.


  METHOD delete_skips_locked_instance.
    " Given two existing roots, one with a FOREIGN_LOCK warning, and a MODIFY warning
    service_manager->rows = NEW /bobf/t_demo_sales_order_hdr_k(
        ( key = first_key root_key = first_key )
        ( key = second_key root_key = second_key ) ).
    service_manager->read_messages = create_messages( key       = first_key
                                                      severity  = 'W'
                                                      is_locked = abap_true ).
    service_manager->modify_messages = create_messages( key      = second_key
                                                        severity = 'W' ).
    service_manager->missing_keys_after_modify = VALUE #( ( key = second_key ) ).

    " When deleting both requested roots
    business_object->delete( EXPORTING node         = `ROOT`
                                        keys        = VALUE #( ( key = first_key ) ( key = second_key ) )
                              IMPORTING failed_keys = DATA(failed_keys)
                                        messages    = DATA(messages) ).

    " Then only the unlocked root is deleted and lock messages precede MODIFY messages
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->modifications
        exp = VALUE /bobf/t_frw_modification(
            ( node        = root_node_key
              change_mode = /bobf/if_frw_c=>sc_modify_delete
              key         = second_key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = first_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->calls
        exp = VALUE string_table( ( `RETRIEVE` ) ( `MODIFY` ) ( `RETRIEVE` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->retrievals[ 1 ]-node_key
                                        exp = root_node_key ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->retrievals[ 1 ]-keys
        exp = VALUE /bobf/t_frw_key( ( key = first_key ) ( key = second_key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->retrievals[ 1 ]-edit_mode
                                        exp = CONV string( /bobf/if_conf_c=>sc_edit_exclusive ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->retrievals[ 2 ]-keys
                                        exp = VALUE /bobf/t_frw_key( ( key = second_key ) ) ).
    cl_abap_unit_assert=>assert_false( service_manager->retrievals[ 2 ]-fill_data ).
    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-key
                                        exp = first_key ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-bapi_return-number
                                        exp = '101' ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 2 ]-key
                                        exp = second_key ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 2 ]-bapi_return-number
                                        exp = '016' ).
  ENDMETHOD.


  METHOD delete_skips_missing_instance.
    " Given one readable root and one missing root
    service_manager->read_failed_keys = VALUE #( ( key = second_key ) ).
    service_manager->missing_keys_after_modify = VALUE #( ( key = first_key ) ).

    " When deleting both requested roots
    business_object->delete( EXPORTING node         = `ROOT`
                                        keys        = VALUE #( ( key = first_key ) ( key = second_key ) )
                              IMPORTING failed_keys = DATA(failed_keys) ).

    " Then only the existing root is sent for deletion and the missing key fails
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->modifications
        exp = VALUE /bobf/t_frw_modification(
            ( node        = root_node_key
              change_mode = /bobf/if_frw_c=>sc_modify_delete
              key         = first_key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = failed_keys
                                        exp = VALUE zif_bfw_business_object=>keys( ( key = second_key ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->calls
        exp = VALUE string_table( ( `RETRIEVE` ) ( `MODIFY` ) ( `RETRIEVE` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        act = service_manager->retrievals[ 1 ]-keys
        exp = VALUE /bobf/t_frw_key( ( key = first_key ) ( key = second_key ) ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->retrievals[ 1 ]-edit_mode
                                        exp = CONV string( /bobf/if_conf_c=>sc_edit_exclusive ) ).
    cl_abap_unit_assert=>assert_equals( act = service_manager->retrievals[ 2 ]-keys
                                        exp = VALUE /bobf/t_frw_key( ( key = first_key ) ) ).
    cl_abap_unit_assert=>assert_false( service_manager->retrievals[ 2 ]-fill_data ).
  ENDMETHOD.
ENDCLASS.
