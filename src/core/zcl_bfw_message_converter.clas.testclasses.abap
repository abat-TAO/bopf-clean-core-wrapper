CLASS ltcl_message_converter DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS business_object_name TYPE string VALUE `/BOBF/DEMO_SALES_ORDER`.
    CONSTANTS instance_key TYPE sysuuid_x16 VALUE '00000000000000000000000000000001'.

    CLASS-DATA business_object_key TYPE /bobf/obm_bo_key.
    CLASS-DATA root_node_key TYPE /bobf/obm_node_key.
    CLASS-DATA long_text_root_key TYPE /bobf/obm_node_key.
    CLASS-DATA long_text_content_key TYPE /bobf/obm_node_key.

    DATA converter TYPE REF TO zcl_bfw_message_converter.
    DATA bopf_messages TYPE REF TO /bobf/if_frw_message.

    CLASS-METHODS class_setup RAISING cx_static_check.
    METHODS setup.
    METHODS add_message
      IMPORTING
        node_key TYPE /bobf/obm_node_key.

    METHODS maps_bapiret2_fields FOR TESTING.
    METHODS names_business_object_and_node FOR TESTING.
    METHODS uses_origin_business_object FOR TESTING.
    METHODS names_dependent_object_root FOR TESTING.
    METHODS qualifies_dependent_subnode FOR TESTING.
    METHODS unknown_node_name_stays_empty FOR TESTING.
    METHODS unbound_container_is_empty FOR TESTING.
ENDCLASS.



CLASS ltcl_message_converter IMPLEMENTATION.

  METHOD class_setup.
    business_object_key = /bobf/cl_frw_factory=>query_bo( CONV #( business_object_name ) ).
    cl_abap_unit_assert=>assert_not_initial( business_object_key ).
    DATA(configuration) = /bobf/cl_frw_factory=>get_configuration( business_object_key ).
    configuration->get_node_tab( IMPORTING et_node = DATA(nodes) ).
    root_node_key = nodes[ node_name = 'ROOT'
                          parent_node_key = VALUE /bobf/obm_node_key( ) ]-node_key.
    configuration->get_assoc_tab( IMPORTING et_assoc = DATA(associations) ).
    long_text_root_key = associations[ KEY key2 COMPONENTS source_node_key = root_node_key
                                                          assoc_name = 'ROOT_LONG_TEXT' ]-target_node_key.
    long_text_content_key = associations[ KEY key2 COMPONENTS source_node_key = long_text_root_key
                                                             assoc_name = 'CONTENT' ]-target_node_key.
    cl_abap_unit_assert=>assert_not_initial( root_node_key ).
    cl_abap_unit_assert=>assert_not_initial( long_text_root_key ).
    cl_abap_unit_assert=>assert_not_initial( long_text_content_key ).
  ENDMETHOD.


  METHOD setup.
    converter = NEW #( ).
    bopf_messages = /bobf/cl_frw_factory=>get_message( ).
  ENDMETHOD.


  METHOD add_message.
    bopf_messages->add_message(
        is_msg       = VALUE #( msgty = 'W'    msgid = 'ZBFW'               msgno = '004'
                                msgv1 = 'ROOT' msgv2 = business_object_name msgv3 = 'Third' msgv4 = 'Fourth' )
        iv_node      = node_key
        iv_key       = instance_key
        iv_attribute = `ORDER_ID` ).
  ENDMETHOD.


  METHOD maps_bapiret2_fields.
    " Given a real BOPF message with four T100 variables and two affected attributes
    add_message( root_node_key ).
    bopf_messages->get( IMPORTING et_message = DATA(entries) ).
    DATA(entry) = entries[ 1 ].
    entry->set_origin_location( VALUE #( BASE entry->ms_origin_location
                                        attributes = VALUE #( ( `ORDER_ID` ) ( `SALES_ORG` ) ) ) ).
    DATA(expected_text) = entry->get_text( ).

    " When converting the message
    DATA(messages) = converter->convert( bopf_messages       = bopf_messages
                                         business_object_key = business_object_key ).

    " Then BAPIRET2 preserves severity, T100 values, text and only the first attribute as FIELD
    cl_abap_unit_assert=>assert_equals( act = lines( messages )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
        act = messages[ 1 ]-bapi_return
        exp = VALUE bapiret2( type       = 'W'
                              id         = 'ZBFW'
                              number     = '004'
                              message    = expected_text
                              message_v1 = 'ROOT'
                              message_v2 = business_object_name
                              message_v3 = 'Third'
                              message_v4 = 'Fourth'
                              field      = 'ORDER_ID' ) ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-severity
                                        exp = 'W' ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-key
                                        exp = instance_key ).
    cl_abap_unit_assert=>assert_equals(
        act = messages[ 1 ]-fields
        exp = VALUE zif_bfw_business_object=>field_names( ( `ORDER_ID` ) ( `SALES_ORG` ) ) ).
  ENDMETHOD.


  METHOD names_business_object_and_node.
    " Given a host-root message without a BO key in its origin
    add_message( root_node_key ).

    " When the caller supplies the BO key as a fallback
    DATA(messages) = converter->convert( bopf_messages       = bopf_messages
                                         business_object_key = business_object_key ).

    " Then the origin uses the host BO and its unqualified root name
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-business_object
                                        exp = business_object_name ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-node
                                        exp = `ROOT` ).
  ENDMETHOD.


  METHOD uses_origin_business_object.
    " Given a message that identifies its BO in the origin
    add_message( root_node_key ).
    bopf_messages->get( IMPORTING et_message = DATA(entries) ).
    DATA(entry) = entries[ 1 ].
    entry->set_origin_location( VALUE #( BASE entry->ms_origin_location
                                        bo_key = business_object_key ) ).

    " When no fallback BO is supplied
    DATA(messages) = converter->convert( bopf_messages ).

    " Then the origin alone resolves the business object and node
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-business_object
                                        exp = business_object_name ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-node
                                        exp = `ROOT` ).
  ENDMETHOD.


  METHOD names_dependent_object_root.
    " Given the runtime DO root, whose configuration name is ROOT
    add_message( long_text_root_key ).

    " When resolving its name through the host configuration
    DATA(messages) = converter->convert( bopf_messages       = bopf_messages
                                         business_object_key = business_object_key ).

    " Then the object association supplies the delegated name
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-business_object
                                        exp = business_object_name ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-node
                                        exp = `ROOT_LONG_TEXT` ).
  ENDMETHOD.


  METHOD qualifies_dependent_subnode.
    " Given CONTENT below the runtime long-text DO root
    add_message( long_text_content_key ).

    " When converting its origin
    DATA(messages) = converter->convert( bopf_messages       = bopf_messages
                                         business_object_key = business_object_key ).

    " Then the object association qualifies the subnode name
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-business_object
                                        exp = business_object_name ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-node
                                        exp = `ROOT_LONG_TEXT.CONTENT` ).
  ENDMETHOD.


  METHOD unknown_node_name_stays_empty.
    " Given a node key absent from the real configuration
    add_message( 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF' ).

    " When the BO is known but its node cannot be resolved
    DATA(messages) = converter->convert( bopf_messages       = bopf_messages
                                         business_object_key = business_object_key ).

    " Then the message remains usable without a node name
    cl_abap_unit_assert=>assert_initial( messages[ 1 ]-node ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-business_object
                                        exp = business_object_name ).
    cl_abap_unit_assert=>assert_equals( act = messages[ 1 ]-key
                                        exp = instance_key ).
  ENDMETHOD.


  METHOD unbound_container_is_empty.
    " Given no message container
    CLEAR bopf_messages.

    " When converting it
    DATA(messages) = converter->convert( bopf_messages ).

    " Then no messages are produced
    cl_abap_unit_assert=>assert_initial( messages ).
  ENDMETHOD.
ENDCLASS.
