"! Engine for one classic BOPF business object: resolves names through ZCL_BFW_METADATA, calls the service
"! manager and maps between the node structures and the caller's row types by component name
CLASS zcl_bfw_business_object DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_bfw_factory.

  PUBLIC SECTION.
    INTERFACES zif_bfw_business_object.

    METHODS constructor
      IMPORTING
        business_object_key TYPE /bobf/obm_bo_key
        service_manager     TYPE REF TO /bobf/if_tra_service_manager
        configuration       TYPE REF TO /bobf/if_frw_configuration.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF row_mapping,
        node_line_type       TYPE REF TO cl_abap_datadescr,
        row_line_type        TYPE REF TO cl_abap_datadescr,
        is_node_type         TYPE abap_bool,
        requested_attributes TYPE /bobf/t_frw_name,
      END OF row_mapping,
      row_mappings TYPE HASHED TABLE OF row_mapping WITH UNIQUE KEY node_line_type row_line_type.

    TYPES:
      BEGIN OF node_instance,
        key      TYPE /bobf/conf_key,
        root_key TYPE /bobf/conf_key,
      END OF node_instance,
      instances TYPE STANDARD TABLE OF node_instance WITH EMPTY KEY.

    TYPES:
      BEGIN OF row_position,
        key   TYPE /bobf/conf_key,
        index TYPE i,
      END OF row_position,
      row_positions TYPE HASHED TABLE OF row_position WITH UNIQUE KEY key.

    DATA business_object_key TYPE /bobf/obm_bo_key.
    DATA business_object_name TYPE string.
    DATA service_manager TYPE REF TO /bobf/if_tra_service_manager.
    DATA metadata TYPE REF TO zcl_bfw_metadata.
    DATA message_converter TYPE REF TO zcl_bfw_message_converter.
    DATA mappings TYPE row_mappings.

    METHODS get_alternative_key_values
      IMPORTING
        alternative_key TYPE zcl_bfw_metadata=>alternative_key_entry
        values          TYPE INDEX TABLE
      RETURNING
        VALUE(result)   TYPE REF TO data.

    "! Structure of PARAMETER_TYPE filled by name from VALUES; each component of VALUES must exist in it
    "! @parameter owner | Action or association the parameters belong to, for the error message
    METHODS create_parameter
      IMPORTING
        owner          TYPE string
        parameter_type TYPE REF TO cl_abap_datadescr
        values         TYPE any
      RETURNING
        VALUE(result)  TYPE REF TO data.

    "! Names of the components of a structure whose value is not initial
    METHODS get_filled_components
      IMPORTING
        structure     TYPE any
      RETURNING
        VALUE(result) TYPE /bobf/t_frw_name.

    METHODS get_query_options
      IMPORTING
        maximum_rows  TYPE i
        sorting       TYPE zif_bfw_business_object=>sorting
        paging        TYPE zif_bfw_business_object=>paging
      RETURNING
        VALUE(result) TYPE /bobf/s_frw_query_options.

    "! Rows of a node in the order of KEYS, as a standard table: the buffer returns them in its own order, and the
    "! table type of the node may be sorted by KEY
    METHODS order_by_keys
      IMPORTING
        node          TYPE zcl_bfw_metadata=>node_entry
        keys          TYPE zif_bfw_business_object=>keys
        node_rows     TYPE INDEX TABLE
      RETURNING
        VALUE(result) TYPE REF TO data.

    METHODS get_row_mapping
      IMPORTING
        node          TYPE zcl_bfw_metadata=>node_entry
        rows          TYPE ANY TABLE
      RETURNING
        VALUE(result) TYPE row_mapping.

    METHODS get_requested_attributes
      IMPORTING
        node          TYPE zcl_bfw_metadata=>node_entry
        row_line_type TYPE REF TO cl_abap_datadescr
      RETURNING
        VALUE(result) TYPE /bobf/t_frw_name.

    "! Checks that each component of the source exists in the target structure
    "! @parameter owner | Node or action the target belongs to, for the error message
    METHODS check_components
      IMPORTING
        owner         TYPE string
        target_type   TYPE REF TO cl_abap_datadescr
        source_type   TYPE REF TO cl_abap_datadescr
      RETURNING
        VALUE(result) TYPE abap_component_view_tab.

    METHODS create_rows
      IMPORTING
        node          TYPE zcl_bfw_metadata=>node_entry
      RETURNING
        VALUE(result) TYPE REF TO data.

    METHODS get_changed_fields
      IMPORTING
        current_row   TYPE any
        new_row       TYPE any
        candidates    TYPE /bobf/t_frw_name
      RETURNING
        VALUE(result) TYPE /bobf/t_frw_name.

    "! @parameter result | Messages of BOPF
    METHODS modify
      IMPORTING
        modifications TYPE /bobf/t_frw_modification
      RETURNING
        VALUE(result) TYPE zif_bfw_business_object=>messages.

    METHODS convert_messages
      IMPORTING
        bopf_messages TYPE REF TO /bobf/if_frw_message
      RETURNING
        VALUE(result) TYPE zif_bfw_business_object=>messages.

    METHODS get_locked_keys
      IMPORTING
        bopf_messages TYPE REF TO /bobf/if_frw_message
        node_rows     TYPE INDEX TABLE
      RETURNING
        VALUE(result) TYPE zif_bfw_business_object=>keys.

    "! Keys without an instance in the transactional buffer. After MODIFY this tells what BOPF did; its messages do not:
    "! BOPF keeps an instance with a consistency error and only reports the error.
    METHODS get_missing_keys
      IMPORTING
        node          TYPE string
        keys          TYPE zif_bfw_business_object=>keys
      RETURNING
        VALUE(result) TYPE zif_bfw_business_object=>keys.

    "! Locks the parents of new rows for update, as MODIFY does implicitly. Some business objects report a foreign
    "! lock on MODIFY only as a warning on the root and drop the change silently; a read for update reveals the lock.
    "! @parameter failed_keys | Parent keys that do not exist or are locked
    METHODS lock_parents
      IMPORTING
        node_entry  TYPE zcl_bfw_metadata=>node_entry
        composition TYPE zcl_bfw_metadata=>composition_entry
        rows        TYPE INDEX TABLE
      EXPORTING
        failed_keys TYPE zif_bfw_business_object=>keys
        messages    TYPE zif_bfw_business_object=>messages.
ENDCLASS.



CLASS zcl_bfw_business_object IMPLEMENTATION.

  METHOD constructor.
    me->business_object_key = business_object_key.
    me->service_manager = service_manager.
    metadata = NEW #( configuration ).
    business_object_name = configuration->ms_obj-bo_name.
    message_converter = NEW #( ).
  ENDMETHOD.


  METHOD zif_bfw_business_object~read.
    DATA mapping TYPE row_mapping.
    DATA node_rows TYPE REF TO data.
    FIELD-SYMBOLS <node_rows> TYPE INDEX TABLE.

    CLEAR: rows, failed_keys, messages.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    DATA(node_entry) = metadata->get_node( node ).
    IF rows IS SUPPLIED.
      mapping = get_row_mapping( node = node_entry
                                 rows = rows ).
    ENDIF.
    IF mapping-is_node_type = abap_true.
      node_rows = REF #( rows ).
    ELSE.
      node_rows = create_rows( node_entry ).
    ENDIF.
    ASSIGN node_rows->* TO <node_rows>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( node_entry-name ).
    ENDIF.

    TRY.
        service_manager->retrieve(
          EXPORTING
            iv_node_key             = node_entry-key
            it_key                  = CORRESPONDING #( keys )
            iv_edit_mode            = COND #( WHEN for_update = abap_true
                                              THEN /bobf/if_conf_c=>sc_edit_exclusive
                                              ELSE /bobf/if_conf_c=>sc_edit_read_only )
            " The lock check needs the root keys of the instances
            iv_fill_data            = xsdbool( rows IS SUPPLIED OR for_update = abap_true )
            iv_before_image         = before_image
            iv_invalidate_cache     = invalidate_cache
            it_requested_attributes = mapping-requested_attributes
          IMPORTING
            eo_message              = DATA(bopf_messages)
            et_data                 = <node_rows>
            et_failed_key           = DATA(bopf_failed_keys) ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = violation ).
    ENDTRY.

    IF rows IS SUPPLIED AND mapping-is_node_type = abap_false.
      MOVE-CORRESPONDING <node_rows> TO rows.
    ENDIF.
    failed_keys = CORRESPONDING #( bopf_failed_keys ).
    IF for_update = abap_true.
      INSERT LINES OF get_locked_keys( bopf_messages = bopf_messages
                                       node_rows     = <node_rows> ) INTO TABLE failed_keys.
    ENDIF.
    IF messages IS SUPPLIED.
      messages = convert_messages( bopf_messages ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_bfw_business_object~read_reference.
    FIELD-SYMBOLS <rows> TYPE INDEX TABLE.

    result = create_rows( metadata->get_node( node ) ).
    ASSIGN result->* TO <rows>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( node ).
    ENDIF.
    zif_bfw_business_object~read( EXPORTING node = node
                                            keys = keys
                                  IMPORTING rows = <rows> ).
  ENDMETHOD.


  METHOD zif_bfw_business_object~read_by_association.
    DATA mapping TYPE row_mapping.
    DATA target_rows TYPE REF TO data.
    DATA parameter TYPE REF TO data.
    DATA filtering_attributes TYPE /bobf/t_frw_name.
    FIELD-SYMBOLS <target_rows> TYPE INDEX TABLE.

    CLEAR: links, rows, failed_keys, messages.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    DATA(source) = metadata->get_node( node ).
    DATA(association_entry) = metadata->get_association( node = source
                                                         name = association ).
    " Without filter values no parameters are sent: an association class may filter on every parameter it gets
    IF filter IS SUPPLIED AND association_entry-parameter_type IS BOUND
        AND ( filter IS NOT INITIAL OR filtered_attributes IS NOT INITIAL ).
      parameter = create_parameter( owner          = association_entry-target-name
                                    parameter_type = association_entry-parameter_type
                                    values         = filter ).
      filtering_attributes = COND #( WHEN filtered_attributes IS NOT INITIAL
                                     THEN VALUE #( FOR attribute IN filtered_attributes ( to_upper( attribute ) ) )
                                     ELSE get_filled_components( filter ) ).
    ENDIF.
    IF rows IS SUPPLIED.
      mapping = get_row_mapping( node = association_entry-target
                                 rows = rows ).
    ENDIF.
    IF mapping-is_node_type = abap_true.
      target_rows = REF #( rows ).
    ELSE.
      target_rows = create_rows( association_entry-target ).
    ENDIF.
    ASSIGN target_rows->* TO <target_rows>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( association_entry-target-name ).
    ENDIF.

    TRY.
        service_manager->retrieve_by_association(
          EXPORTING
            iv_node_key             = source-key
            it_key                  = CORRESPONDING #( keys )
            iv_association          = association_entry-key
            is_parameters           = parameter
            it_filtered_attributes  = filtering_attributes
            iv_fill_data            = xsdbool( rows IS SUPPLIED )
            iv_before_image         = before_image
            iv_invalidate_cache     = invalidate_cache
            it_requested_attributes = mapping-requested_attributes
          IMPORTING
            eo_message              = DATA(bopf_messages)
            et_data                 = <target_rows>
            et_key_link             = DATA(bopf_links)
            et_failed_key           = DATA(bopf_failed_keys) ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = violation ).
    ENDTRY.

    IF rows IS SUPPLIED AND mapping-is_node_type = abap_false.
      MOVE-CORRESPONDING <target_rows> TO rows.
    ENDIF.
    links = CORRESPONDING #( bopf_links ).
    failed_keys = CORRESPONDING #( bopf_failed_keys ).
    IF messages IS SUPPLIED.
      messages = convert_messages( bopf_messages ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_bfw_business_object~convert_alternative_key.
    DATA read_messages TYPE zif_bfw_business_object=>messages.
    FIELD-SYMBOLS <bopf_values> TYPE INDEX TABLE.

    CLEAR: keys, key_indexes, rows, messages.
    IF values IS INITIAL.
      RETURN.
    ENDIF.

    DATA(node_entry) = metadata->get_node( node ).
    DATA(alternative_key_entry) = metadata->get_alternative_key( node = node_entry
                                                                 name = alternative_key ).
    DATA(bopf_values) = get_alternative_key_values( alternative_key = alternative_key_entry
                                                    values          = values ).
    ASSIGN bopf_values->* TO <bopf_values>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( |{ node_entry-name }.{ alternative_key_entry-name }| ).
    ENDIF.

    TRY.
        service_manager->convert_altern_key(
          EXPORTING
            iv_node_key         = node_entry-key
            iv_altkey_key       = alternative_key_entry-key
            it_key              = <bopf_values>
            iv_before_image     = before_image
            iv_invalidate_cache = invalidate_cache
          IMPORTING
            eo_message          = DATA(bopf_messages)
            et_result           = DATA(key_results) ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = violation ).
    ENDTRY.

    key_indexes = VALUE #( FOR key_result IN key_results WHERE ( key IS NOT INITIAL )
                           ( index = key_result-index
                             key   = key_result-key ) ).
    keys = VALUE #( FOR key_index IN key_indexes ( key = key_index-key ) ).
    SORT keys BY key.
    DELETE ADJACENT DUPLICATES FROM keys COMPARING key.
    IF messages IS SUPPLIED.
      messages = convert_messages( bopf_messages ).
    ENDIF.

    IF rows IS SUPPLIED.
      zif_bfw_business_object~read( EXPORTING node             = node
                                              keys             = keys
                                              before_image     = before_image
                                              invalidate_cache = invalidate_cache
                                    IMPORTING rows             = rows
                                              messages         = read_messages ).
      INSERT LINES OF read_messages INTO TABLE messages.
    ENDIF.
  ENDMETHOD.


  METHOD zif_bfw_business_object~query.
    DATA node_rows TYPE REF TO data.
    DATA read_messages TYPE zif_bfw_business_object=>messages.
    FIELD-SYMBOLS <node_rows> TYPE INDEX TABLE.
    FIELD-SYMBOLS <ordered_rows> TYPE INDEX TABLE.

    CLEAR: keys, rows, messages.
    DATA(node_entry) = metadata->get_node( node ).
    DATA(query_key) = metadata->get_query_key( node = node_entry
                                               name = query ).

    TRY.
        service_manager->query(
          EXPORTING
            iv_query_key            = query_key
            it_filter_key           = CORRESPONDING #( filter_keys )
            it_selection_parameters = CORRESPONDING #( selection_parameters )
            is_query_options        = get_query_options( maximum_rows = maximum_rows
                                                         sorting      = sorting
                                                         paging       = paging )
          IMPORTING
            eo_message              = DATA(bopf_messages)
            et_key                  = DATA(bopf_keys) ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = violation ).
    ENDTRY.

    keys = CORRESPONDING #( bopf_keys ).
    IF messages IS SUPPLIED.
      messages = convert_messages( bopf_messages ).
    ENDIF.
    IF rows IS NOT SUPPLIED.
      RETURN.
    ENDIF.

    " The rows come from the transactional buffer, so they include changes not yet saved; the buffer returns them
    " in its own order, so they are put back into the order of the query result
    DATA(mapping) = get_row_mapping( node = node_entry
                                     rows = rows ).
    node_rows = create_rows( node_entry ).
    ASSIGN node_rows->* TO <node_rows>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( node_entry-name ).
    ENDIF.
    zif_bfw_business_object~read( EXPORTING node     = node
                                            keys     = keys
                                  IMPORTING rows     = <node_rows>
                                            messages = read_messages ).
    INSERT LINES OF read_messages INTO TABLE messages.

    DATA(ordered_rows) = order_by_keys( node      = node_entry
                                        keys      = keys
                                        node_rows = <node_rows> ).
    ASSIGN ordered_rows->* TO <ordered_rows>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( node_entry-name ).
    ENDIF.
    IF mapping-is_node_type = abap_true.
      rows = <ordered_rows>.
    ELSE.
      MOVE-CORRESPONDING <ordered_rows> TO rows.
    ENDIF.
  ENDMETHOD.


  METHOD zif_bfw_business_object~create.
    DATA modifications TYPE /bobf/t_frw_modification.
    DATA requested_keys TYPE zif_bfw_business_object=>keys.
    DATA node_row TYPE REF TO data.
    DATA parent_key TYPE /bobf/conf_key.
    DATA failed_parent_keys TYPE zif_bfw_business_object=>keys.
    DATA lock_messages TYPE zif_bfw_business_object=>messages.
    DATA modify_messages TYPE zif_bfw_business_object=>messages.
    FIELD-SYMBOLS <node_row> TYPE any.
    FIELD-SYMBOLS <key> TYPE any.
    FIELD-SYMBOLS <row_key> TYPE any.
    FIELD-SYMBOLS <parent_key> TYPE any.

    CLEAR: failed_keys, messages.
    IF rows IS INITIAL.
      RETURN.
    ENDIF.

    DATA(node_entry) = metadata->get_node( node ).
    DATA(composition) = metadata->get_composition( node_entry ).
    DATA(mapping) = get_row_mapping( node = node_entry
                                     rows = rows ).
    DATA(node_line_type) = node_entry-table_type->get_table_line_type( ).
    lock_parents( EXPORTING node_entry  = node_entry
                            composition = composition
                            rows        = rows
                  IMPORTING failed_keys = failed_parent_keys
                            messages    = lock_messages ).

    LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).
      CREATE DATA node_row TYPE HANDLE node_line_type.
      ASSIGN node_row->* TO <node_row>.
      IF sy-subrc <> 0.
        zcx_bfw_access=>raise_missing_data_type( node_entry-name ).
      ENDIF.
      MOVE-CORRESPONDING <row> TO <node_row>.

      ASSIGN COMPONENT 'KEY' OF STRUCTURE <node_row> TO <key>.
      IF sy-subrc <> 0.
        zcx_bfw_access=>raise_missing_component( node      = node_entry-name
                                                 component = 'KEY' ).
      ENDIF.
      IF <key> IS INITIAL.
        <key> = service_manager->get_new_key( ).
        ASSIGN COMPONENT 'KEY' OF STRUCTURE <row> TO <row_key>.
        IF sy-subrc = 0.
          <row_key> = <key>.
        ENDIF.
      ENDIF.

      CLEAR parent_key.
      IF composition-parent_node_key IS NOT INITIAL.
        ASSIGN COMPONENT 'PARENT_KEY' OF STRUCTURE <row> TO <parent_key>.
        IF sy-subrc <> 0.
          zcx_bfw_access=>raise_missing_component( node      = node_entry-name
                                                   component = 'PARENT_KEY' ).
        ENDIF.
        parent_key = <parent_key>.
      ENDIF.
      " A row whose parent does not exist or is locked is not sent; its generated key stays in the row
      IF line_exists( failed_parent_keys[ key = parent_key ] ).
        INSERT VALUE #( key = <key> ) INTO TABLE failed_keys.
        CONTINUE.
      ENDIF.

      INSERT VALUE #( node           = node_entry-key
                      change_mode    = /bobf/if_frw_c=>sc_modify_create
                      key            = <key>
                      data           = node_row
                      changed_fields = mapping-requested_attributes
                      association    = composition-association_key
                      source_node    = composition-parent_node_key
                      source_key     = parent_key ) INTO TABLE modifications.
      INSERT VALUE #( key = <key> ) INTO TABLE requested_keys.
    ENDLOOP.

    modify_messages = modify( modifications ).
    " A create that BOPF dropped leaves no instance
    INSERT LINES OF get_missing_keys( node = node
                                      keys = requested_keys ) INTO TABLE failed_keys.
    messages = VALUE #( BASE lock_messages ( LINES OF modify_messages ) ).
  ENDMETHOD.


  METHOD zif_bfw_business_object~update.
    DATA requested_keys TYPE zif_bfw_business_object=>keys.
    DATA current_rows TYPE REF TO data.
    DATA new_row TYPE REF TO data.
    DATA modifications TYPE /bobf/t_frw_modification.
    DATA fields TYPE /bobf/t_frw_name.
    DATA position TYPE i.
    DATA read_messages TYPE zif_bfw_business_object=>messages.
    DATA modify_messages TYPE zif_bfw_business_object=>messages.
    FIELD-SYMBOLS <current_rows> TYPE INDEX TABLE.
    FIELD-SYMBOLS <current_row> TYPE any.
    FIELD-SYMBOLS <new_row> TYPE any.
    FIELD-SYMBOLS <key> TYPE any.

    CLEAR: failed_keys, messages.
    IF rows IS INITIAL.
      RETURN.
    ENDIF.

    DATA(node_entry) = metadata->get_node( node ).
    DATA(mapping) = get_row_mapping( node = node_entry
                                     rows = rows ).
    DATA(node_line_type) = node_entry-table_type->get_table_line_type( ).
    " The caller's own fields are compared; a row of the node type compares all node attributes
    DATA(candidates) = COND /bobf/t_frw_name( WHEN mapping-is_node_type = abap_false
                                              THEN mapping-requested_attributes
                                              WHEN node_entry-field_names IS BOUND
                                              THEN node_entry-field_names->* ).
    DATA(fields_to_send) = VALUE /bobf/t_frw_name( FOR field IN changed_fields ( to_upper( field ) ) ).

    LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).
      ASSIGN COMPONENT 'KEY' OF STRUCTURE <row> TO <key>.
      IF sy-subrc <> 0.
        zcx_bfw_access=>raise_missing_component( node      = node_entry-name
                                                 component = 'KEY' ).
      ENDIF.
      INSERT VALUE #( key = <key> ) INTO TABLE requested_keys.
    ENDLOOP.

    " The current state is the base of the comparison; reading it for update also locks the instances
    current_rows = create_rows( node_entry ).
    ASSIGN current_rows->* TO <current_rows>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( node_entry-name ).
    ENDIF.
    zif_bfw_business_object~read( EXPORTING node        = node
                                            keys        = requested_keys
                                            for_update  = abap_true
                                  IMPORTING rows        = <current_rows>
                                            failed_keys = failed_keys
                                            messages    = read_messages ).
    DATA(current_instances) = CORRESPONDING instances( <current_rows> ).
    DATA(positions) = VALUE row_positions( FOR current_instance IN current_instances INDEX INTO index
                                           ( key   = current_instance-key
                                             index = index ) ).

    LOOP AT rows ASSIGNING <row>.
      ASSIGN COMPONENT 'KEY' OF STRUCTURE <row> TO <key>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      " Instances that do not exist or are locked keep their failed key and are not changed
      position = VALUE #( positions[ key = <key> ]-index OPTIONAL ).
      IF position = 0 OR line_exists( failed_keys[ key = <key> ] ).
        CONTINUE.
      ENDIF.
      READ TABLE <current_rows> INDEX position ASSIGNING <current_row>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      CREATE DATA new_row TYPE HANDLE node_line_type.
      ASSIGN new_row->* TO <new_row>.
      IF sy-subrc <> 0.
        zcx_bfw_access=>raise_missing_data_type( node_entry-name ).
      ENDIF.
      <new_row> = <current_row>.
      MOVE-CORRESPONDING <row> TO <new_row>.

      fields = COND #( WHEN fields_to_send IS NOT INITIAL
                       THEN fields_to_send
                       ELSE get_changed_fields( current_row = <current_row>
                                                new_row     = <new_row>
                                                candidates  = candidates ) ).
      " An empty field list would overwrite the whole instance
      IF fields IS INITIAL.
        CONTINUE.
      ENDIF.
      INSERT VALUE #( node           = node_entry-key
                      change_mode    = /bobf/if_frw_c=>sc_modify_update
                      key            = <key>
                      data           = new_row
                      changed_fields = fields ) INTO TABLE modifications.
    ENDLOOP.

    " BOPF keeps a change with a consistency error and only reports the error, so only the instances that the read for
    " update did not find or lock fail
    modify_messages = modify( modifications ).
    SORT failed_keys BY key.
    DELETE ADJACENT DUPLICATES FROM failed_keys COMPARING key.
    messages = VALUE #( BASE read_messages ( LINES OF modify_messages ) ).
  ENDMETHOD.


  METHOD zif_bfw_business_object~delete.
    DATA modifications TYPE /bobf/t_frw_modification.
    DATA requested_keys TYPE zif_bfw_business_object=>keys.
    DATA lock_messages TYPE zif_bfw_business_object=>messages.
    DATA modify_messages TYPE zif_bfw_business_object=>messages.

    CLEAR: failed_keys, messages.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    DATA(node_entry) = metadata->get_node( node ).
    " Locked first, as MODIFY does implicitly: some business objects report a foreign lock on MODIFY only as a
    " warning and drop the deletion silently. Instances that do not exist or are locked are not sent.
    zif_bfw_business_object~read( EXPORTING node        = node
                                            keys        = keys
                                            for_update  = abap_true
                                  IMPORTING failed_keys = failed_keys
                                            messages    = lock_messages ).
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      IF NOT line_exists( failed_keys[ key = <key>-key ] ).
        INSERT VALUE #( node        = node_entry-key
                        change_mode = /bobf/if_frw_c=>sc_modify_delete
                        key         = <key>-key ) INTO TABLE modifications.
        INSERT <key> INTO TABLE requested_keys.
      ENDIF.
    ENDLOOP.

    modify_messages = modify( modifications ).
    " A deletion that BOPF dropped leaves the instance
    DATA(missing_keys) = get_missing_keys( node = node
                                           keys = requested_keys ).
    LOOP AT requested_keys ASSIGNING FIELD-SYMBOL(<requested_key>).
      IF NOT line_exists( missing_keys[ key = <requested_key>-key ] ).
        INSERT <requested_key> INTO TABLE failed_keys.
      ENDIF.
    ENDLOOP.
    messages = VALUE #( BASE lock_messages ( LINES OF modify_messages ) ).
  ENDMETHOD.


  METHOD zif_bfw_business_object~execute_action.
    DATA mapping TYPE row_mapping.
    DATA parameter TYPE REF TO data.
    DATA result_rows TYPE REF TO data.
    DATA no_result TYPE zif_bfw_business_object=>keys.
    FIELD-SYMBOLS <result_rows> TYPE INDEX TABLE.

    CLEAR: rows, failed_keys, messages.
    DATA(node_entry) = metadata->get_node( node ).
    DATA(action_entry) = metadata->get_action( node = node_entry
                                               name = action ).
    IF parameters IS SUPPLIED AND action_entry-parameter_type IS BOUND.
      parameter = create_parameter( owner          = action_entry-result-name
                                    parameter_type = action_entry-parameter_type
                                    values         = parameters ).
    ENDIF.

    IF rows IS SUPPLIED AND action_entry-result-table_type IS BOUND.
      mapping = get_row_mapping( node = action_entry-result
                                 rows = rows ).
    ENDIF.
    IF mapping-is_node_type = abap_true.
      result_rows = REF #( rows ).
    ELSEIF action_entry-result-table_type IS BOUND.
      result_rows = create_rows( action_entry-result ).
    ELSE.
      result_rows = REF #( no_result ).
    ENDIF.
    ASSIGN result_rows->* TO <result_rows>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( action_entry-result-name ).
    ENDIF.

    TRY.
        service_manager->do_action(
          EXPORTING
            iv_act_key           = action_entry-key
            it_key               = CORRESPONDING #( keys )
            is_parameters        = parameter
          IMPORTING
            eo_message           = DATA(bopf_messages)
            et_failed_key        = DATA(bopf_failed_keys)
            et_failed_action_key = DATA(bopf_failed_action_keys)
            et_data              = <result_rows> ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = violation ).
    ENDTRY.

    IF rows IS SUPPLIED AND mapping-is_node_type = abap_false AND action_entry-result-table_type IS BOUND.
      MOVE-CORRESPONDING <result_rows> TO rows.
    ENDIF.
    failed_keys = CORRESPONDING #( bopf_failed_keys ).
    INSERT LINES OF CORRESPONDING zif_bfw_business_object=>keys( bopf_failed_action_keys ) INTO TABLE failed_keys.
    SORT failed_keys BY key.
    DELETE ADJACENT DUPLICATES FROM failed_keys COMPARING key.
    IF messages IS SUPPLIED.
      messages = convert_messages( bopf_messages ).
    ENDIF.
  ENDMETHOD.


  METHOD get_alternative_key_values.
    DATA key_table_type TYPE REF TO cl_abap_tabledescr.
    FIELD-SYMBOLS <key_values> TYPE INDEX TABLE.

    DATA(value_line_type) = CAST cl_abap_tabledescr(
                              cl_abap_typedescr=>describe_by_data( values ) )->get_table_line_type( ).
    DATA(key_line_type) = alternative_key-table_type->get_table_line_type( ).
    IF value_line_type = key_line_type.
      result = REF #( values ).
      RETURN.
    ENDIF.

    " BOPF expects the line type of the alternative key; a standard table keeps the positions of VALUES
    TRY.
        key_table_type = cl_abap_tabledescr=>get( p_line_type = key_line_type
                                                  p_key_kind  = cl_abap_tabledescr=>keydefkind_empty ).
      CATCH cx_sy_table_creation.
        zcx_bfw_access=>raise_missing_data_type( alternative_key-name ).
    ENDTRY.
    CREATE DATA result TYPE HANDLE key_table_type.
    ASSIGN result->* TO <key_values>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( alternative_key-name ).
    ENDIF.

    IF key_line_type IS INSTANCE OF cl_abap_structdescr.
      MOVE-CORRESPONDING values TO <key_values>.
      RETURN.
    ENDIF.
    LOOP AT values ASSIGNING FIELD-SYMBOL(<value>).
      INSERT INITIAL LINE INTO TABLE <key_values> ASSIGNING FIELD-SYMBOL(<key_value>).
      <key_value> = <value>.
    ENDLOOP.
  ENDMETHOD.


  METHOD create_parameter.
    FIELD-SYMBOLS <parameter> TYPE any.

    CREATE DATA result TYPE HANDLE parameter_type.
    ASSIGN result->* TO <parameter>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( owner ).
    ENDIF.
    check_components( owner       = owner
                      target_type = parameter_type
                      source_type = CAST #( cl_abap_typedescr=>describe_by_data( values ) ) ).
    MOVE-CORRESPONDING values TO <parameter>.
  ENDMETHOD.


  METHOD get_filled_components.
    FIELD-SYMBOLS <value> TYPE any.

    DATA(components) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( structure ) )->get_included_view( ).
    LOOP AT components ASSIGNING FIELD-SYMBOL(<component>).
      ASSIGN COMPONENT <component>-name OF STRUCTURE structure TO <value>.
      IF sy-subrc = 0 AND <value> IS NOT INITIAL.
        INSERT <component>-name INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_query_options.
    result = VALUE #( maximum_rows    = maximum_rows
                      sorting_options = VALUE #( FOR criterion IN sorting
                                                 ( attribute_name = to_upper( criterion-attribute_name )
                                                   ascending      = xsdbool( criterion-descending = abap_false ) ) )
                      paging_options  = VALUE #( paging_active = xsdbool( paging IS NOT INITIAL )
                                                 start_row     = paging-start_row
                                                 start_key     = paging-start_key ) ).
  ENDMETHOD.


  METHOD order_by_keys.
    DATA positions TYPE row_positions.
    DATA position TYPE i.
    DATA ordered_table_type TYPE REF TO cl_abap_tabledescr.
    FIELD-SYMBOLS <ordered_rows> TYPE INDEX TABLE.

    DATA(read_instances) = CORRESPONDING instances( node_rows ).
    LOOP AT read_instances ASSIGNING FIELD-SYMBOL(<read_instance>).
      position = sy-tabix.
      INSERT VALUE #( key   = <read_instance>-key
                      index = position ) INTO TABLE positions.
    ENDLOOP.

    TRY.
        ordered_table_type = cl_abap_tabledescr=>get( p_line_type = node-table_type->get_table_line_type( )
                                                      p_key_kind  = cl_abap_tabledescr=>keydefkind_empty ).
      CATCH cx_sy_table_creation.
        zcx_bfw_access=>raise_missing_data_type( node-name ).
    ENDTRY.
    CREATE DATA result TYPE HANDLE ordered_table_type.
    ASSIGN result->* TO <ordered_rows>.
    IF sy-subrc <> 0.
      zcx_bfw_access=>raise_missing_data_type( node-name ).
    ENDIF.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      position = VALUE #( positions[ key = <key>-key ]-index OPTIONAL ).
      IF position = 0.
        CONTINUE.
      ENDIF.
      READ TABLE node_rows INDEX position ASSIGNING FIELD-SYMBOL(<node_row>).
      IF sy-subrc = 0.
        INSERT <node_row> INTO TABLE <ordered_rows>.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_row_mapping.
    DATA(row_line_type) = CAST cl_abap_tabledescr(
                            cl_abap_typedescr=>describe_by_data( rows ) )->get_table_line_type( ).
    DATA(node_line_type) = node-table_type->get_table_line_type( ).
    result = VALUE #( mappings[ node_line_type = node_line_type
                                row_line_type  = row_line_type ] OPTIONAL ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    result = VALUE #( node_line_type = node_line_type
                      row_line_type  = row_line_type
                      is_node_type   = xsdbool( row_line_type = node_line_type ) ).
    IF result-is_node_type = abap_false.
      result-requested_attributes = get_requested_attributes( node          = node
                                                              row_line_type = row_line_type ).
    ENDIF.
    INSERT result INTO TABLE mappings.
  ENDMETHOD.


  METHOD get_requested_attributes.
    DATA(row_components) = check_components( owner       = node-name
                                             target_type = node-table_type->get_table_line_type( )
                                             source_type = row_line_type ).
    " Key components are not node attributes; BOPF always fills them
    IF node-field_names IS NOT BOUND.
      RETURN.
    ENDIF.
    LOOP AT row_components ASSIGNING FIELD-SYMBOL(<row_component>).
      IF line_exists( node-field_names->*[ table_line = <row_component>-name ] ).
        INSERT <row_component>-name INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD check_components.
    IF source_type IS NOT INSTANCE OF cl_abap_structdescr OR target_type IS NOT INSTANCE OF cl_abap_structdescr.
      zcx_bfw_access=>raise_unstructured_rows( owner ).
    ENDIF.

    DATA(target_components) = CAST cl_abap_structdescr( target_type )->get_included_view( ).
    result = CAST cl_abap_structdescr( source_type )->get_included_view( ).
    LOOP AT result ASSIGNING FIELD-SYMBOL(<component>).
      IF NOT line_exists( target_components[ name = <component>-name ] ).
        zcx_bfw_access=>raise_unknown_component( component = <component>-name
                                                 node      = owner ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD create_rows.
    CREATE DATA result TYPE HANDLE node-table_type.
  ENDMETHOD.


  METHOD get_changed_fields.
    FIELD-SYMBOLS <current_value> TYPE any.
    FIELD-SYMBOLS <new_value> TYPE any.

    LOOP AT candidates ASSIGNING FIELD-SYMBOL(<candidate>).
      ASSIGN COMPONENT <candidate> OF STRUCTURE current_row TO <current_value>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT <candidate> OF STRUCTURE new_row TO <new_value>.
      IF sy-subrc = 0 AND <new_value> <> <current_value>.
        INSERT <candidate> INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD modify.
    IF modifications IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        service_manager->modify( EXPORTING it_modification = modifications
                                 IMPORTING eo_message      = DATA(bopf_messages) ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = violation ).
    ENDTRY.

    result = convert_messages( bopf_messages ).
  ENDMETHOD.


  METHOD convert_messages.
    result = message_converter->convert( bopf_messages       = bopf_messages
                                         business_object_key = business_object_key ).
  ENDMETHOD.


  METHOD get_locked_keys.
    DATA locked_keys TYPE SORTED TABLE OF /bobf/conf_key WITH UNIQUE KEY table_line.

    IF bopf_messages IS NOT BOUND.
      RETURN.
    ENDIF.

    bopf_messages->get( IMPORTING et_message = DATA(entries) ).
    LOOP AT entries ASSIGNING FIELD-SYMBOL(<entry>)
         WHERE table_line->symptom = /bobf/if_frw_message_symptoms=>co_foreign_lock.
      INSERT <entry>->ms_origin_location-key INTO TABLE locked_keys.
    ENDLOOP.
    IF locked_keys IS INITIAL.
      RETURN.
    ENDIF.

    " The lock can be reported for the root instance, so an instance also counts as locked through its root
    DATA(read_instances) = CORRESPONDING instances( node_rows ).
    LOOP AT read_instances ASSIGNING FIELD-SYMBOL(<read_instance>).
      IF line_exists( locked_keys[ table_line = <read_instance>-key ] )
          OR line_exists( locked_keys[ table_line = <read_instance>-root_key ] ).
        INSERT VALUE #( key = <read_instance>-key ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_missing_keys.
    zif_bfw_business_object~read( EXPORTING node        = node
                                            keys        = keys
                                  IMPORTING failed_keys = result ).
  ENDMETHOD.


  METHOD lock_parents.
    DATA parent_keys TYPE zif_bfw_business_object=>keys.
    DATA parent_node TYPE string.
    FIELD-SYMBOLS <parent_key> TYPE any.

    CLEAR: failed_keys, messages.
    IF composition-parent_node_key IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).
      ASSIGN COMPONENT 'PARENT_KEY' OF STRUCTURE <row> TO <parent_key>.
      IF sy-subrc <> 0.
        zcx_bfw_access=>raise_missing_component( node      = node_entry-name
                                                 component = 'PARENT_KEY' ).
      ENDIF.
      INSERT VALUE #( key = <parent_key> ) INTO TABLE parent_keys.
    ENDLOOP.
    SORT parent_keys BY key.
    DELETE ADJACENT DUPLICATES FROM parent_keys COMPARING key.

    TRY.
        parent_node = metadata->get_node_name( composition-parent_node_key ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = violation ).
    ENDTRY.
    zif_bfw_business_object~read( EXPORTING node        = parent_node
                                            keys        = parent_keys
                                            for_update  = abap_true
                                  IMPORTING failed_keys = failed_keys
                                            messages    = messages ).
  ENDMETHOD.
ENDCLASS.
