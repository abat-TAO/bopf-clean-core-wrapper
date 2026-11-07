"! Metadata of one classic BOPF business object, resolved by name from its configuration: nodes, associations,
"! alternative keys, queries and actions with their data types. A dependent object is named after the object
"! association to its root: the association name addresses the root, its other nodes are qualified with it, e.g.
"! ROOT_LONG_TEXT.CONTENT. Unknown or ambiguous names raise ZCX_BFW_ACCESS.
CLASS zcl_bfw_metadata DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF node_entry,
        name                          TYPE string,
        key                           TYPE /bobf/obm_node_key,
        parent_node_key               TYPE /bobf/obm_node_key,
        data_table_type               TYPE string,
        reference_business_object_key TYPE /bobf/obm_bo_key,
        reference_node_key            TYPE /bobf/obm_node_key,
        field_names                   TYPE REF TO /bobf/t_frw_name,
        table_type                    TYPE REF TO cl_abap_tabledescr,
      END OF node_entry.

    TYPES:
      BEGIN OF association_entry,
        node_key       TYPE /bobf/obm_node_key,
        name           TYPE string,
        key            TYPE /bobf/obm_assoc_key,
        target         TYPE node_entry,
        "! Filter parameters of the association; not bound = the association has none
        parameter_type TYPE REF TO cl_abap_datadescr,
      END OF association_entry.

    TYPES:
      BEGIN OF composition_entry,
        node_key        TYPE /bobf/obm_node_key,
        parent_node_key TYPE /bobf/obm_node_key,
        association_key TYPE /bobf/obm_assoc_key,
      END OF composition_entry.

    TYPES:
      BEGIN OF alternative_key_entry,
        node_key   TYPE /bobf/obm_node_key,
        name       TYPE string,
        key        TYPE /bobf/obm_altkey_key,
        table_type TYPE REF TO cl_abap_tabledescr,
      END OF alternative_key_entry.

    TYPES:
      BEGIN OF action_entry,
        node_key       TYPE /bobf/obm_node_key,
        name           TYPE string,
        key            TYPE /bobf/act_key,
        parameter_type TYPE REF TO cl_abap_datadescr,
        "! Result rows as a pseudo node: name for messages and table type; no table type = no result
        result         TYPE node_entry,
      END OF action_entry.

    CONSTANTS:
      "! Kinds of names that GET_SELECTABLE_NAMES lists
      BEGIN OF selectable_kinds,
        node            TYPE string VALUE `node`,
        association     TYPE string VALUE `association`,
        alternative_key TYPE string VALUE `alternative_key`,
        action          TYPE string VALUE `action`,
        query           TYPE string VALUE `query`,
      END OF selectable_kinds.

    TYPES:
      BEGIN OF selectable_name,
        name TYPE string,
        info TYPE string,
      END OF selectable_name,
      selectable_names TYPE SORTED TABLE OF selectable_name WITH UNIQUE KEY name.

    METHODS constructor
      IMPORTING
        configuration TYPE REF TO /bobf/if_frw_configuration.

    "! @parameter name | Node name; nodes of a dependent object are qualified, see the class description
    METHODS get_node
      IMPORTING
        name          TYPE string
      RETURNING
        VALUE(result) TYPE node_entry.

    "! Name of any node of the configuration in the form that GET_NODE expects
    METHODS get_node_name
      IMPORTING
        node_key      TYPE /bobf/obm_node_key
      RETURNING
        VALUE(result) TYPE string
      RAISING
        /bobf/cx_frw_contrct_violation.

    "! @parameter result | Association with its target; the target of a cross-BO association has the table type of
    "!                     the other business object
    METHODS get_association
      IMPORTING
        node          TYPE node_entry
        name          TYPE string
      RETURNING
        VALUE(result) TYPE association_entry.

    "! Association from the parent node through which instances of the node are created
    METHODS get_composition
      IMPORTING
        node          TYPE node_entry
      RETURNING
        VALUE(result) TYPE composition_entry.

    METHODS get_alternative_key
      IMPORTING
        node          TYPE node_entry
        name          TYPE string
      RETURNING
        VALUE(result) TYPE alternative_key_entry.

    METHODS get_query_key
      IMPORTING
        node          TYPE node_entry
        name          TYPE string
      RETURNING
        VALUE(result) TYPE /bobf/obm_query_key.

    METHODS get_action
      IMPORTING
        node          TYPE node_entry
        name          TYPE string
      RETURNING
        VALUE(result) TYPE action_entry.

    "! Names that the other methods of this class resolve, e.g. for a value help: nodes (a dependent object's nodes
    "! qualified, see the class description) or NODE.NAME for associations, alternative keys, actions and queries.
    "! Left out: message, property and lock nodes, associations to them, and ambiguous node names.
    "! @parameter kind   | One of SELECTABLE_KINDS; any other kind gives no names
    "! @parameter result | Names with a short info: table type, association target (cross-BO: business object and
    "!                     node), action parameter and result type, query parameter type
    METHODS get_selectable_names
      IMPORTING
        kind          TYPE string
      RETURNING
        VALUE(result) TYPE selectable_names.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES node_entries TYPE SORTED TABLE OF node_entry WITH NON-UNIQUE KEY name
      WITH UNIQUE HASHED KEY by_key COMPONENTS key.
    TYPES association_entries TYPE HASHED TABLE OF association_entry WITH UNIQUE KEY node_key name.
    TYPES composition_entries TYPE HASHED TABLE OF composition_entry WITH UNIQUE KEY node_key.
    TYPES alternative_key_entries TYPE HASHED TABLE OF alternative_key_entry WITH UNIQUE KEY node_key name.
    TYPES action_entries TYPE HASHED TABLE OF action_entry WITH UNIQUE KEY node_key name.

    TYPES:
      BEGIN OF query_entry,
        node_key TYPE /bobf/obm_node_key,
        name     TYPE string,
        key      TYPE /bobf/obm_query_key,
      END OF query_entry,
      query_entries TYPE HASHED TABLE OF query_entry WITH UNIQUE KEY node_key name.

    DATA configuration TYPE REF TO /bobf/if_frw_configuration.
    DATA business_object_name TYPE string.
    DATA nodes TYPE node_entries.
    DATA associations TYPE association_entries.
    DATA compositions TYPE composition_entries.
    DATA alternative_keys TYPE alternative_key_entries.
    DATA queries TYPE query_entries.
    DATA actions TYPE action_entries.

    METHODS load_nodes.

    METHODS get_qualified_name
      IMPORTING
        node                       TYPE /bobf/s_confro_node
        association_configurations TYPE /bobf/t_confro_assoc
      RETURNING
        VALUE(result)              TYPE string.

    METHODS to_node_entry
      IMPORTING
        node          TYPE /bobf/s_confro_node
      RETURNING
        VALUE(result) TYPE node_entry.

    METHODS get_table_type
      IMPORTING
        node          TYPE node_entry
      RETURNING
        VALUE(result) TYPE REF TO cl_abap_tabledescr.

    "! @parameter owner | Node, action or alternative key the type belongs to, for the error message
    METHODS describe_type
      IMPORTING
        type_name     TYPE csequence
        owner         TYPE string
      RETURNING
        VALUE(result) TYPE REF TO cl_abap_datadescr.

    METHODS get_foreign_data_table_type
      IMPORTING
        node          TYPE node_entry
      RETURNING
        VALUE(result) TYPE string.

    METHODS get_action_result
      IMPORTING
        action_configuration TYPE /bobf/s_confro_act_list
        name                 TYPE string
      RETURNING
        VALUE(result)        TYPE node_entry.

    "! Name of a node that carries instance data and resolves uniquely; empty for any other node
    METHODS get_selectable_node_name
      IMPORTING
        node_key      TYPE /bobf/obm_node_key
      RETURNING
        VALUE(result) TYPE string.

    METHODS get_selectable_nodes
      RETURNING
        VALUE(result) TYPE selectable_names.

    METHODS get_selectable_associations
      RETURNING
        VALUE(result) TYPE selectable_names.

    "! Target of an association: its node name, for a cross-BO association the business object and node it represents
    METHODS get_association_target_name
      IMPORTING
        target                     TYPE /bobf/s_confro_node
        association_configurations TYPE /bobf/t_confro_assoc
      RETURNING
        VALUE(result)              TYPE string.

    METHODS get_selectable_altkeys
      RETURNING
        VALUE(result) TYPE selectable_names.

    METHODS get_selectable_actions
      RETURNING
        VALUE(result) TYPE selectable_names.

    METHODS get_selectable_queries
      RETURNING
        VALUE(result) TYPE selectable_names.
ENDCLASS.



CLASS zcl_bfw_metadata IMPLEMENTATION.

  METHOD constructor.
    me->configuration = configuration.
    business_object_name = configuration->ms_obj-bo_name.
  ENDMETHOD.


  METHOD get_node_name.
    configuration->get_node( EXPORTING iv_node_key = node_key
                             IMPORTING es_node     = DATA(node) ).
    configuration->get_assoc_tab( IMPORTING et_assoc = DATA(association_configurations) ).
    result = get_qualified_name( node                       = node
                                 association_configurations = association_configurations ).
  ENDMETHOD.


  METHOD get_node.
    IF nodes IS INITIAL.
      load_nodes( ).
    ENDIF.

    DATA(upper_name) = to_upper( name ).
    DATA(match_count) = REDUCE i( INIT count = 0
                                  FOR node IN nodes WHERE ( name = upper_name )
                                  NEXT count = count + 1 ).
    IF match_count = 0.
      zcx_bfw_access=>raise_unknown_node( node            = name
                                          business_object = business_object_name ).
    ENDIF.
    IF match_count > 1.
      zcx_bfw_access=>raise_ambiguous_node( node            = name
                                            business_object = business_object_name ).
    ENDIF.

    result = nodes[ name = upper_name ].
    IF result-table_type IS NOT BOUND.
      result-table_type = get_table_type( result ).
      MODIFY TABLE nodes FROM result USING KEY by_key TRANSPORTING table_type.
    ENDIF.
  ENDMETHOD.


  METHOD load_nodes.
    DATA node TYPE node_entry.

    configuration->get_node_tab( IMPORTING et_node = DATA(node_configurations) ).
    configuration->get_assoc_tab( IMPORTING et_assoc = DATA(association_configurations) ).

    " Only these nodes carry instance data; at run time BOPF replaces a delegated node by the root of its dependent object
    LOOP AT node_configurations ASSIGNING FIELD-SYMBOL(<node_configuration>)
         WHERE node_type = /bobf/if_conf_c=>sc_node_type_normal
            OR node_type = /bobf/if_conf_c=>sc_node_type_do.
      node = to_node_entry( <node_configuration> ).
      node-name = get_qualified_name( node                       = <node_configuration>
                                      association_configurations = association_configurations ).
      INSERT node INTO TABLE nodes.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_qualified_name.
    result = node-node_name.
    IF node-delegation_root_node_key IS INITIAL.
      RETURN.
    ENDIF.

    " The root of a dependent object keeps its own name (ROOT); the name of the delegated node survives only as the
    " object association to that root, and the other nodes of the dependent object are qualified with it
    DATA(delegated_node_name) = VALUE string(
      association_configurations[ target_node_key = node-delegation_root_node_key
                                  assoc_cat       = /bobf/if_conf_c=>sc_assoccat_object ]-assoc_name OPTIONAL ).
    IF delegated_node_name IS INITIAL.
      RETURN.
    ENDIF.
    result = COND #( WHEN node-node_key = node-delegation_root_node_key
                     THEN delegated_node_name
                     ELSE |{ delegated_node_name }.{ result }| ).
  ENDMETHOD.


  METHOD to_node_entry.
    result = VALUE #( name                          = node-node_name
                      key                           = node-node_key
                      parent_node_key               = node-parent_node_key
                      data_table_type               = node-data_table_type
                      reference_business_object_key = node-ref_bo_key
                      reference_node_key            = node-ref_node_key
                      field_names                   = node-field_names ).
  ENDMETHOD.


  METHOD get_table_type.
    DATA(data_table_type) = node-data_table_type.
    IF data_table_type IS INITIAL AND node-reference_node_key IS NOT INITIAL.
      data_table_type = get_foreign_data_table_type( node ).
    ENDIF.

    DATA(description) = describe_type( type_name = data_table_type
                                       owner     = node-name ).
    IF description IS NOT INSTANCE OF cl_abap_tabledescr.
      zcx_bfw_access=>raise_missing_data_type( node-name ).
    ENDIF.
    result = CAST #( description ).
  ENDMETHOD.


  METHOD describe_type.
    cl_abap_typedescr=>describe_by_name(
      EXPORTING
        p_name         = type_name
      RECEIVING
        p_descr_ref    = DATA(description)
      EXCEPTIONS
        type_not_found = 1
        OTHERS         = 2 ).
    IF sy-subrc <> 0 OR description IS NOT INSTANCE OF cl_abap_datadescr.
      zcx_bfw_access=>raise_missing_data_type( owner ).
    ENDIF.
    result = CAST #( description ).
  ENDMETHOD.


  METHOD get_foreign_data_table_type.
    " The node represents a node of another business object, which defines its type
    TRY.
        DATA(foreign_configuration) = /bobf/cl_frw_factory=>get_configuration( node-reference_business_object_key ).
        foreign_configuration->get_node( EXPORTING iv_node_key = node-reference_node_key
                                         IMPORTING es_node     = DATA(foreign_node) ).
        result = foreign_node-data_table_type.
      CATCH /bobf/cx_frw /bobf/cx_frw_contrct_violation INTO DATA(error).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = error ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_association.
    DATA(upper_name) = to_upper( name ).
    result = VALUE #( associations[ node_key = node-key
                                    name     = upper_name ] OPTIONAL ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA(association_key) = configuration->query_assoc( iv_node_key   = node-key
                                                        iv_assoc_name = CONV #( upper_name ) ).
    IF association_key IS INITIAL.
      zcx_bfw_access=>raise_unknown_association( association = name
                                                 node        = node-name ).
    ENDIF.

    TRY.
        configuration->get_assoc( EXPORTING iv_assoc_key = association_key
                                  IMPORTING es_assoc     = DATA(association_configuration) ).
        configuration->get_node( EXPORTING iv_node_key = association_configuration-target_node_key
                                 IMPORTING es_node     = DATA(target_configuration) ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = violation ).
    ENDTRY.

    DATA(target) = to_node_entry( target_configuration ).
    target-name = |{ node-name }.{ upper_name }|.
    target-table_type = get_table_type( target ).
    result = VALUE #( node_key = node-key
                      name     = upper_name
                      key      = association_key
                      target   = target ).
    IF association_configuration-param_data_type IS NOT INITIAL.
      result-parameter_type = describe_type( type_name = association_configuration-param_data_type
                                             owner     = target-name ).
    ENDIF.
    INSERT result INTO TABLE associations.
  ENDMETHOD.


  METHOD get_composition.
    DATA association_configurations TYPE /bobf/t_confro_assoc.

    result = VALUE #( compositions[ node_key = node-key ] OPTIONAL ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    result = VALUE #( node_key        = node-key
                      parent_node_key = node-parent_node_key ).
    IF node-parent_node_key IS NOT INITIAL.
      configuration->get_assoc_tab( IMPORTING et_assoc = association_configurations ).
      " A delegated node hangs at its host node by an object association, any other subnode by a composition
      LOOP AT association_configurations ASSIGNING FIELD-SYMBOL(<association_configuration>)
           WHERE source_node_key = node-parent_node_key
             AND target_node_key = node-key
             AND ( assoc_cat = /bobf/if_conf_c=>sc_assoccat_object
                OR assoc_type = /bobf/if_conf_c=>sc_assoctype_comp ).
        result-association_key = <association_configuration>-assoc_key.
        EXIT.
      ENDLOOP.
    ENDIF.
    INSERT result INTO TABLE compositions.
  ENDMETHOD.


  METHOD get_alternative_key.
    DATA(upper_name) = to_upper( name ).
    result = VALUE #( alternative_keys[ node_key = node-key
                                        name     = upper_name ] OPTIONAL ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA(alternative_key_key) = configuration->query_altkey( iv_node_key    = node-key
                                                             iv_altkey_name = CONV #( upper_name ) ).
    IF alternative_key_key IS INITIAL.
      zcx_bfw_access=>raise_unknown_alternative_key( alternative_key = name
                                                     node            = node-name ).
    ENDIF.

    TRY.
        configuration->get_altkey( EXPORTING iv_altkey_key = alternative_key_key
                                   IMPORTING es_altkey     = DATA(alternative_key_configuration) ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = violation ).
    ENDTRY.

    result = VALUE #( node_key   = node-key
                      name       = upper_name
                      key        = alternative_key_key
                      table_type = get_table_type(
                                     VALUE #( name            = |{ node-name }.{ upper_name }|
                                              data_table_type = alternative_key_configuration-data_table_type ) ) ).
    INSERT result INTO TABLE alternative_keys.
  ENDMETHOD.


  METHOD get_query_key.
    DATA(upper_name) = to_upper( name ).
    result = VALUE #( queries[ node_key = node-key
                               name     = upper_name ]-key OPTIONAL ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    result = configuration->query_query( iv_node_key   = node-key
                                         iv_query_name = CONV #( upper_name ) ).
    IF result IS INITIAL.
      zcx_bfw_access=>raise_unknown_query( query = name
                                           node  = node-name ).
    ENDIF.
    INSERT VALUE #( node_key = node-key
                    name     = upper_name
                    key      = result ) INTO TABLE queries.
  ENDMETHOD.


  METHOD get_action.
    DATA(upper_name) = to_upper( name ).
    result = VALUE #( actions[ node_key = node-key
                               name     = upper_name ] OPTIONAL ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA(action_key) = configuration->query_action( iv_node_key = node-key
                                                    iv_act_name = CONV #( upper_name ) ).
    IF action_key IS INITIAL.
      zcx_bfw_access=>raise_unknown_action( action = name
                                            node   = node-name ).
    ENDIF.

    TRY.
        configuration->get_act( EXPORTING iv_act_key = action_key
                                IMPORTING es_action  = DATA(action_configuration) ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object_name
                                          previous        = violation ).
    ENDTRY.

    result = VALUE #( node_key = node-key
                      name     = upper_name
                      key      = action_key
                      result   = get_action_result( action_configuration = action_configuration
                                                    name                 = |{ node-name }.{ upper_name }| ) ).
    IF action_configuration-param_data_type IS NOT INITIAL.
      result-parameter_type = describe_type( type_name = action_configuration-param_data_type
                                             owner     = result-result-name ).
    ENDIF.
    INSERT result INTO TABLE actions.
  ENDMETHOD.


  METHOD get_action_result.
    result-name = name.
    IF action_configuration-export_param_tt IS NOT INITIAL.
      result-table_type = get_table_type( VALUE #( name            = name
                                                   data_table_type = action_configuration-export_param_tt ) ).
      RETURN.
    ENDIF.
    IF action_configuration-export_param_s IS INITIAL.
      RETURN.
    ENDIF.

    " Only the structure is configured; the rows are a standard table of it
    TRY.
        result-table_type = cl_abap_tabledescr=>get(
                              p_line_type = describe_type( type_name = action_configuration-export_param_s
                                                           owner     = name )
                              p_key_kind  = cl_abap_tabledescr=>keydefkind_empty ).
      CATCH cx_sy_table_creation.
        zcx_bfw_access=>raise_missing_data_type( name ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_selectable_names.
    IF nodes IS INITIAL.
      load_nodes( ).
    ENDIF.

    result = SWITCH #( kind
                       WHEN selectable_kinds-node            THEN get_selectable_nodes( )
                       WHEN selectable_kinds-association     THEN get_selectable_associations( )
                       WHEN selectable_kinds-alternative_key THEN get_selectable_altkeys( )
                       WHEN selectable_kinds-action          THEN get_selectable_actions( )
                       WHEN selectable_kinds-query           THEN get_selectable_queries( ) ).
  ENDMETHOD.


  METHOD get_selectable_node_name.
    result = VALUE #( nodes[ KEY by_key key = node_key ]-name OPTIONAL ).
    " GET_NODE refuses an ambiguous name
    IF result IS NOT INITIAL AND lines( FILTER #( nodes WHERE name = result ) ) > 1.
      CLEAR result.
    ENDIF.
  ENDMETHOD.


  METHOD get_selectable_nodes.
    LOOP AT nodes ASSIGNING FIELD-SYMBOL(<node>).
      IF get_selectable_node_name( <node>-key ) IS NOT INITIAL.
        INSERT VALUE #( name = <node>-name
                        info = <node>-data_table_type ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_selectable_associations.
    DATA source_name TYPE string.
    DATA target TYPE /bobf/s_confro_node.

    configuration->get_node_tab( IMPORTING et_node = DATA(node_configurations) ).
    configuration->get_assoc_tab( IMPORTING et_assoc = DATA(association_configurations) ).
    LOOP AT association_configurations ASSIGNING FIELD-SYMBOL(<association_configuration>).
      source_name = get_selectable_node_name( <association_configuration>-source_node_key ).
      target = VALUE #( node_configurations[ node_key = <association_configuration>-target_node_key ] OPTIONAL ).
      " Message, property and lock nodes carry no instance data
      IF source_name IS INITIAL
          OR NOT (    target-node_type = /bobf/if_conf_c=>sc_node_type_normal
                   OR target-node_type = /bobf/if_conf_c=>sc_node_type_do
                   OR target-node_type = /bobf/if_conf_c=>sc_node_type_bo ).
        CONTINUE.
      ENDIF.
      INSERT VALUE #( name = |{ source_name }.{ <association_configuration>-assoc_name }|
                      info = get_association_target_name(
                               target                     = target
                               association_configurations = association_configurations ) ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_association_target_name.
    IF target-node_type <> /bobf/if_conf_c=>sc_node_type_bo.
      result = get_qualified_name( node                       = target
                                   association_configurations = association_configurations ).
      RETURN.
    ENDIF.

    " The node represents a node of another business object
    TRY.
        DATA(foreign_configuration) = /bobf/cl_frw_factory=>get_configuration( target-ref_bo_key ).
        foreign_configuration->get_node( EXPORTING iv_node_key = target-ref_node_key
                                         IMPORTING es_node     = DATA(foreign_node) ).
        result = |{ foreign_configuration->ms_obj-bo_name } { foreign_node-node_name }|.
      CATCH /bobf/cx_frw /bobf/cx_frw_contrct_violation.
        result = target-node_name.
    ENDTRY.
  ENDMETHOD.


  METHOD get_selectable_altkeys.
    DATA node_name TYPE string.

    configuration->get_altkey_tab( IMPORTING et_altkey = DATA(altkey_configurations) ).
    LOOP AT altkey_configurations ASSIGNING FIELD-SYMBOL(<altkey_configuration>).
      node_name = get_selectable_node_name( <altkey_configuration>-node_key ).
      IF node_name IS NOT INITIAL.
        INSERT VALUE #( name = |{ node_name }.{ <altkey_configuration>-altkey_name }|
                        info = <altkey_configuration>-data_table_type ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_selectable_actions.
    DATA node_name TYPE string.
    DATA info TYPE string.

    configuration->get_act_tab( IMPORTING et_action = DATA(action_configurations) ).
    LOOP AT action_configurations ASSIGNING FIELD-SYMBOL(<action_configuration>).
      node_name = get_selectable_node_name( <action_configuration>-node_key ).
      IF node_name IS INITIAL.
        CONTINUE.
      ENDIF.
      " Parameter structure, then -> and the result type, if any
      info = <action_configuration>-param_data_type.
      IF <action_configuration>-export_param_tt IS NOT INITIAL.
        info = condense( |{ info } -> { <action_configuration>-export_param_tt }| ).
      ELSEIF <action_configuration>-export_param_s IS NOT INITIAL.
        info = condense( |{ info } -> { <action_configuration>-export_param_s }| ).
      ENDIF.
      INSERT VALUE #( name = |{ node_name }.{ <action_configuration>-act_name }|
                      info = info ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_selectable_queries.
    DATA node_name TYPE string.

    configuration->get_query_tab( IMPORTING et_query = DATA(query_configurations) ).
    LOOP AT query_configurations ASSIGNING FIELD-SYMBOL(<query_configuration>).
      node_name = get_selectable_node_name( <query_configuration>-node_key ).
      IF node_name IS NOT INITIAL.
        INSERT VALUE #( name = |{ node_name }.{ <query_configuration>-query_name }|
                        info = <query_configuration>-data_type ) INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
