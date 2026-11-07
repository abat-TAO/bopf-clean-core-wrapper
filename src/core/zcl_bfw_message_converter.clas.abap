"! Converts the messages of a BOPF message container into the message format of the BOPF wrapper, with the names of
"! the business object and node each message comes from
CLASS zcl_bfw_message_converter DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! @parameter business_object_key | Business object of messages whose origin location has none
    METHODS convert
      IMPORTING
        bopf_messages       TYPE REF TO /bobf/if_frw_message
        business_object_key TYPE /bobf/obm_bo_key OPTIONAL
      RETURNING
        VALUE(result)       TYPE zif_bfw_business_object=>messages.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF origin,
        business_object_key TYPE /bobf/obm_bo_key,
        node_key            TYPE /bobf/obm_node_key,
        business_object     TYPE string,
        node                TYPE string,
      END OF origin,
      origins TYPE HASHED TABLE OF origin WITH UNIQUE KEY business_object_key node_key.

    DATA known_origins TYPE origins.

    METHODS get_origin
      IMPORTING
        business_object_key TYPE /bobf/obm_bo_key
        node_key            TYPE /bobf/obm_node_key
      RETURNING
        VALUE(result)       TYPE origin.

    METHODS get_node_name
      IMPORTING
        business_object_key TYPE /bobf/obm_bo_key
        node_key            TYPE /bobf/obm_node_key
      RETURNING
        VALUE(result)       TYPE string
      RAISING
        /bobf/cx_frw
        /bobf/cx_frw_contrct_violation.
ENDCLASS.



CLASS zcl_bfw_message_converter IMPLEMENTATION.

  METHOD convert.
    DATA t100 TYPE symsg.
    DATA fields TYPE zif_bfw_business_object=>field_names.
    DATA origin TYPE origin.

    IF bopf_messages IS NOT BOUND.
      RETURN.
    ENDIF.

    bopf_messages->get( IMPORTING et_message = DATA(entries) ).
    LOOP AT entries ASSIGNING FIELD-SYMBOL(<entry>).
      t100 = cl_message_helper=>get_t100_for_object( <entry> ).
      fields = VALUE #( FOR attribute IN <entry>->ms_origin_location-attributes ( attribute ) ).
      origin = get_origin( business_object_key = COND #( WHEN <entry>->ms_origin_location-bo_key IS INITIAL
                                                         THEN business_object_key
                                                         ELSE <entry>->ms_origin_location-bo_key )
                           node_key            = <entry>->ms_origin_location-node_key ).
      INSERT VALUE #( severity        = <entry>->severity
                      business_object = origin-business_object
                      node            = origin-node
                      key             = <entry>->ms_origin_location-key
                      fields          = fields
                      bapi_return     = VALUE #( type       = <entry>->severity
                                                 id         = t100-msgid
                                                 number     = t100-msgno
                                                 message    = <entry>->get_text( )
                                                 message_v1 = t100-msgv1
                                                 message_v2 = t100-msgv2
                                                 message_v3 = t100-msgv3
                                                 message_v4 = t100-msgv4
                                                 field      = COND #( WHEN fields IS NOT INITIAL THEN fields[ 1 ] ) ) )
             INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_origin.
    IF business_object_key IS INITIAL.
      RETURN.
    ENDIF.
    result = VALUE #( known_origins[ business_object_key = business_object_key
                                     node_key            = node_key ] OPTIONAL ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    result = VALUE #( business_object_key = business_object_key
                      node_key            = node_key ).
    TRY.
        result-business_object = /bobf/cl_frw_factory=>get_bo_name( business_object_key ).
        result-node = get_node_name( business_object_key = business_object_key
                                     node_key            = node_key ).
      CATCH /bobf/cx_frw /bobf/cx_frw_contrct_violation.
        " A message stays usable without the names, e.g. for a node key that the configuration does not know
        CLEAR result-node.
    ENDTRY.
    INSERT result INTO TABLE known_origins.
  ENDMETHOD.


  METHOD get_node_name.
    " Loading the configuration of a RAP business object without draft context dumps
    IF node_key IS INITIAL OR /bobf/cl_frw_factory=>is_rap_bo( business_object_key ) = abap_true.
      RETURN.
    ENDIF.

    DATA(metadata) = NEW zcl_bfw_metadata( /bobf/cl_frw_factory=>get_configuration( business_object_key ) ).
    result = metadata->get_node_name( node_key ).
  ENDMETHOD.
ENDCLASS.
