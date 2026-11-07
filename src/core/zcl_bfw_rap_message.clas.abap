"! A message of the BOPF wrapper as RAP message object (IF_ABAP_BEHV_MESSAGE) for the REPORTED response of a RAP
"! business object that works with BOPF through the wrapper. Deliberately no exception class, so it cannot be raised
"! or declared after RAISING. A message without a T100 key keeps its full text in GET_TEXT; readers of the T100 key
"! get it as the generic message 00 001, split into its variables.
CLASS zcl_bfw_rap_message DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES if_abap_behv_message.

    TYPES:
      "! A message with what a RAP business object needs to put it into REPORTED: its origin and the message object
      BEGIN OF rap_message,
        business_object TYPE string,
        node            TYPE string,
        key             TYPE zif_bfw_business_object=>instance_key,
        fields          TYPE zif_bfw_business_object=>field_names,
        message         TYPE REF TO if_abap_behv_message,
      END OF rap_message,
      rap_messages TYPE STANDARD TABLE OF rap_message WITH EMPTY KEY.

    "! One RAP message per message of the wrapper, in the same order
    CLASS-METHODS from_messages
      IMPORTING
        messages      TYPE zif_bfw_business_object=>messages
      RETURNING
        VALUE(result) TYPE rap_messages.

    METHODS constructor
      IMPORTING
        message TYPE zif_bfw_business_object=>message.

  PROTECTED SECTION.
  PRIVATE SECTION.
    "! Full text of a message without a T100 key
    DATA text TYPE string.

    "! Severity of a BAPIRET2 message type; an abort or any unknown type counts as error
    CLASS-METHODS get_severity
      IMPORTING
        message_type  TYPE bapiret2-type
      RETURNING
        VALUE(result) TYPE if_abap_behv_message=>t_severity.
ENDCLASS.



CLASS zcl_bfw_rap_message IMPLEMENTATION.

  METHOD from_messages.
    result = VALUE #( FOR entry IN messages
                      ( business_object = entry-business_object
                        node            = entry-node
                        key             = entry-key
                        fields          = entry-fields
                        message         = NEW zcl_bfw_rap_message( entry ) ) ).
  ENDMETHOD.


  METHOD constructor.
    DATA(t100) = message-bapi_return.
    if_abap_behv_message~m_severity = get_severity( message-severity ).
    if_t100_dyn_msg~msgty = SWITCH #( if_abap_behv_message~m_severity
                                      WHEN if_abap_behv_message=>severity-warning     THEN 'W'
                                      WHEN if_abap_behv_message=>severity-information THEN 'I'
                                      WHEN if_abap_behv_message=>severity-success     THEN 'S'
                                      ELSE 'E' ).

    " Without a T100 key GET_TEXT returns the full text; readers of the T100 key get the generic message 00 001
    IF t100-id IS INITIAL.
      text = t100-message.
      cl_message_helper=>set_msg_vars_for_clike( t100-message ).
      t100-id = sy-msgid.
      t100-number = sy-msgno.
      t100-message_v1 = sy-msgv1.
      t100-message_v2 = sy-msgv2.
      t100-message_v3 = sy-msgv3.
      t100-message_v4 = sy-msgv4.
    ENDIF.

    if_t100_message~t100key = VALUE #( msgid = t100-id
                                       msgno = t100-number
                                       attr1 = 'IF_T100_DYN_MSG~MSGV1'
                                       attr2 = 'IF_T100_DYN_MSG~MSGV2'
                                       attr3 = 'IF_T100_DYN_MSG~MSGV3'
                                       attr4 = 'IF_T100_DYN_MSG~MSGV4' ).
    if_t100_dyn_msg~msgv1 = t100-message_v1.
    if_t100_dyn_msg~msgv2 = t100-message_v2.
    if_t100_dyn_msg~msgv3 = t100-message_v3.
    if_t100_dyn_msg~msgv4 = t100-message_v4.
  ENDMETHOD.


  METHOD if_message~get_text.
    IF text IS NOT INITIAL.
      result = text.
      RETURN.
    ENDIF.
    MESSAGE ID if_t100_message~t100key-msgid TYPE 'S' NUMBER if_t100_message~t100key-msgno
            WITH if_t100_dyn_msg~msgv1 if_t100_dyn_msg~msgv2 if_t100_dyn_msg~msgv3 if_t100_dyn_msg~msgv4
            INTO result.
  ENDMETHOD.


  METHOD if_message~get_longtext.
    result = if_message~get_text( ).
  ENDMETHOD.


  METHOD get_severity.
    result = SWITCH #( message_type
                       WHEN 'W' THEN if_abap_behv_message=>severity-warning
                       WHEN 'I' THEN if_abap_behv_message=>severity-information
                       WHEN 'S' THEN if_abap_behv_message=>severity-success
                       ELSE if_abap_behv_message=>severity-error ).
  ENDMETHOD.
ENDCLASS.
