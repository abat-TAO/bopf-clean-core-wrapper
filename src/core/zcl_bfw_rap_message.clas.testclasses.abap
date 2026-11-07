CLASS ltcl_rap_message DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS keeps_order_and_routing FOR TESTING.
    METHODS keeps_t100_message FOR TESTING.
    METHODS maps_message_severities FOR TESTING.
    METHODS keeps_free_text FOR TESTING.
    METHODS keeps_long_free_text FOR TESTING.
    METHODS keeps_words_at_chunk_boundary FOR TESTING.
    METHODS empty_input_is_empty FOR TESTING.
ENDCLASS.



CLASS ltcl_rap_message IMPLEMENTATION.

  METHOD keeps_order_and_routing.
    DATA rap_message TYPE zcl_bfw_rap_message=>rap_message.
    DATA expected TYPE zif_bfw_business_object=>message.

    " Given differently routed messages in a non-alphabetical order and one without routing data
    DATA(messages) = VALUE zif_bfw_business_object=>messages(
        ( business_object = `SECOND_BO`
          node            = `ITEM`
          key             = '00000000000000000000000000000002'
          fields          = VALUE #( ( `DESCRIPTION` ) ( `AMOUNT` ) )
          bapi_return     = VALUE #( message = 'First message' ) )
        ( business_object = `FIRST_BO`
          node            = `ROOT`
          key             = '00000000000000000000000000000001'
          fields          = VALUE #( ( `ORDER_ID` ) )
          bapi_return     = VALUE #( message = 'Second message' ) )
        ( bapi_return = VALUE #( message = 'Unrouted message' ) ) ).

    " When converting the messages for RAP
    DATA(rap_messages) = zcl_bfw_rap_message=>from_messages( messages ).

    " Then every row keeps its position, routing data and corresponding message
    cl_abap_unit_assert=>assert_equals( act = lines( rap_messages )
                                        exp = 3 ).
    LOOP AT rap_messages INTO rap_message.
      expected = messages[ sy-tabix ].
      cl_abap_unit_assert=>assert_equals( act = rap_message-business_object
                                          exp = expected-business_object ).
      cl_abap_unit_assert=>assert_equals( act = rap_message-node
                                          exp = expected-node ).
      cl_abap_unit_assert=>assert_equals( act = rap_message-key
                                          exp = expected-key ).
      cl_abap_unit_assert=>assert_equals( act = rap_message-fields
                                          exp = expected-fields ).
      cl_abap_unit_assert=>assert_bound( rap_message-message ).
      cl_abap_unit_assert=>assert_equals( act = rap_message-message->if_message~get_text( )
                                          exp = expected-bapi_return-message ).
    ENDLOOP.
  ENDMETHOD.


  METHOD keeps_t100_message.
    " Given a T100 message with four variables and a different cached text
    DATA(messages) = VALUE zif_bfw_business_object=>messages(
        ( severity    = 'E'
          bapi_return = VALUE #(
              id         = 'ZBFW'
              number     = '004'
              message    = 'Cached text must not override T100'
              message_v1 = 'ROOT'
              message_v2 = 'SALES_ORDER'
              message_v3 = 'Third'
              message_v4 = 'Fourth' ) ) ).
    DATA(t100) = messages[ 1 ]-bapi_return.
    MESSAGE ID t100-id TYPE 'E' NUMBER t100-number
            WITH t100-message_v1 t100-message_v2 INTO DATA(expected_text).

    " When converting the message for RAP
    DATA(rap_messages) = zcl_bfw_rap_message=>from_messages( messages ).

    " Then the T100 key, dynamic variables and rendered text survive
    cl_abap_unit_assert=>assert_equals( act = lines( rap_messages )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_bound( rap_messages[ 1 ]-message ).
    DATA(message) = rap_messages[ 1 ]-message.
    cl_abap_unit_assert=>assert_equals(
        act = message->if_t100_message~t100key
        exp = VALUE scx_t100key( msgid = 'ZBFW'
                                 msgno = '004'
                                 attr1 = 'IF_T100_DYN_MSG~MSGV1'
                                 attr2 = 'IF_T100_DYN_MSG~MSGV2'
                                 attr3 = 'IF_T100_DYN_MSG~MSGV3'
                                 attr4 = 'IF_T100_DYN_MSG~MSGV4' ) ).
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_dyn_msg~msgv1
                                        exp = 'ROOT' ).
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_dyn_msg~msgv2
                                        exp = 'SALES_ORDER' ).
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_dyn_msg~msgv3
                                        exp = 'Third' ).
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_dyn_msg~msgv4
                                        exp = 'Fourth' ).
    cl_abap_unit_assert=>assert_equals( act = message->if_message~get_text( )
                                        exp = expected_text ).
    cl_abap_unit_assert=>assert_equals( act = message->if_message~get_longtext( )
                                        exp = message->if_message~get_text( ) ).
  ENDMETHOD.


  METHOD maps_message_severities.
    TYPES:
      BEGIN OF severity_case,
        message_type TYPE bapiret2-type,
        severity     TYPE if_abap_behv_message=>t_severity,
        dynamic_type TYPE bapiret2-type,
      END OF severity_case,
      severity_cases TYPE STANDARD TABLE OF severity_case WITH EMPTY KEY.

    DATA rap_message TYPE zcl_bfw_rap_message=>rap_message.
    DATA expected TYPE severity_case.
    DATA message TYPE REF TO if_abap_behv_message.

    " Given every supported severity, an unknown type and a blank, independently of BAPIRET2-TYPE
    DATA(cases) = VALUE severity_cases(
        ( message_type = 'E' severity = if_abap_behv_message=>severity-error       dynamic_type = 'E' )
        ( message_type = 'A' severity = if_abap_behv_message=>severity-error       dynamic_type = 'E' )
        ( message_type = 'W' severity = if_abap_behv_message=>severity-warning     dynamic_type = 'W' )
        ( message_type = 'I' severity = if_abap_behv_message=>severity-information dynamic_type = 'I' )
        ( message_type = 'S' severity = if_abap_behv_message=>severity-success     dynamic_type = 'S' )
        ( message_type = '?' severity = if_abap_behv_message=>severity-error       dynamic_type = 'E' )
        ( message_type = space severity = if_abap_behv_message=>severity-error     dynamic_type = 'E' ) ).
    DATA(messages) = VALUE zif_bfw_business_object=>messages(
        FOR entry IN cases
        ( severity    = entry-message_type
          bapi_return = VALUE #( type = 'S' id = 'ZBFW' number = '004' ) ) ).

    " When converting the messages for RAP
    DATA(rap_messages) = zcl_bfw_rap_message=>from_messages( messages ).

    " Then RAP severity and the dynamic message type follow the wrapper severity and default to error
    cl_abap_unit_assert=>assert_equals( act = lines( rap_messages )
                                        exp = lines( cases ) ).
    LOOP AT rap_messages INTO rap_message.
      expected = cases[ sy-tabix ].
      cl_abap_unit_assert=>assert_bound( rap_message-message ).
      message = rap_message-message.
      cl_abap_unit_assert=>assert_equals( act = message->m_severity
                                          exp = expected-severity
                                          msg = |Message severity "{ expected-message_type }"| ).
      cl_abap_unit_assert=>assert_equals( act = message->if_t100_dyn_msg~msgty
                                          exp = expected-dynamic_type
                                          msg = |Dynamic message type for severity "{ expected-message_type }"| ).
    ENDLOOP.
  ENDMETHOD.


  METHOD keeps_free_text.
    " Given a message with text but no T100 key
    DATA(text) = `A message supplied without a T100 key`.
    DATA(messages) = VALUE zif_bfw_business_object=>messages(
        ( bapi_return = VALUE #( message = text ) ) ).

    " When converting the message for RAP
    DATA(rap_messages) = zcl_bfw_rap_message=>from_messages( messages ).

    " Then the original text is available through IF_MESSAGE and the generic T100 key
    cl_abap_unit_assert=>assert_equals( act = lines( rap_messages )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_bound( rap_messages[ 1 ]-message ).
    DATA(message) = rap_messages[ 1 ]-message.
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_message~t100key-msgid
                                        exp = '00' ).
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_message~t100key-msgno
                                        exp = '001' ).
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_dyn_msg~msgv1
                                        exp = text ).
    cl_abap_unit_assert=>assert_initial( message->if_t100_dyn_msg~msgv2 ).
    cl_abap_unit_assert=>assert_initial( message->if_t100_dyn_msg~msgv3 ).
    cl_abap_unit_assert=>assert_initial( message->if_t100_dyn_msg~msgv4 ).
    cl_abap_unit_assert=>assert_equals( act = message->if_message~get_text( )
                                        exp = text ).
    cl_abap_unit_assert=>assert_equals( act = message->if_message~get_longtext( )
                                        exp = text ).
  ENDMETHOD.


  METHOD keeps_long_free_text.
    " Given a 122-character free text spanning three message variables
    DATA(text) = `This message contains more than fifty characters and must remain complete when it is passed to a RAP consumer for display.`.
    DATA(messages) = VALUE zif_bfw_business_object=>messages(
        ( bapi_return = VALUE #( message = text ) ) ).

    " When converting the message for RAP
    DATA(rap_messages) = zcl_bfw_rap_message=>from_messages( messages ).

    " Then the full text survives through IF_MESSAGE and the generic T100 message
    cl_abap_unit_assert=>assert_equals( act = lines( rap_messages )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_bound( rap_messages[ 1 ]-message ).
    DATA(message) = rap_messages[ 1 ]-message.
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_message~t100key-msgid
                                        exp = '00' ).
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_message~t100key-msgno
                                        exp = '001' ).
    MESSAGE ID message->if_t100_message~t100key-msgid TYPE 'S'
            NUMBER message->if_t100_message~t100key-msgno
            WITH message->if_t100_dyn_msg~msgv1
                 message->if_t100_dyn_msg~msgv2
                 message->if_t100_dyn_msg~msgv3
                 message->if_t100_dyn_msg~msgv4
            INTO DATA(t100_text).
    cl_abap_unit_assert=>assert_equals( act = t100_text
                                        exp = text ).
    cl_abap_unit_assert=>assert_equals( act = message->if_message~get_text( )
                                        exp = text ).
    cl_abap_unit_assert=>assert_equals( act = message->if_message~get_longtext( )
                                        exp = text ).
  ENDMETHOD.


  METHOD keeps_words_at_chunk_boundary.
    " Given a free text whose fiftieth character is the blank between two words
    DATA(text) = `The separator at the end of this first segment is followed by words that must stay separated.`.
    DATA(messages) = VALUE zif_bfw_business_object=>messages(
        ( bapi_return = VALUE #( message = text ) ) ).

    " When converting the message for RAP
    DATA(rap_messages) = zcl_bfw_rap_message=>from_messages( messages ).

    " Then both IF_MESSAGE and the T100 message preserve the word separator
    cl_abap_unit_assert=>assert_equals( act = lines( rap_messages )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_bound( rap_messages[ 1 ]-message ).
    DATA(message) = rap_messages[ 1 ]-message.
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_message~t100key-msgid
                                        exp = '00' ).
    cl_abap_unit_assert=>assert_equals( act = message->if_t100_message~t100key-msgno
                                        exp = '001' ).
    MESSAGE ID message->if_t100_message~t100key-msgid TYPE 'S'
            NUMBER message->if_t100_message~t100key-msgno
            WITH message->if_t100_dyn_msg~msgv1
                 message->if_t100_dyn_msg~msgv2
                 message->if_t100_dyn_msg~msgv3
                 message->if_t100_dyn_msg~msgv4
            INTO DATA(t100_text).
    cl_abap_unit_assert=>assert_equals( act = t100_text
                                        exp = text ).
    cl_abap_unit_assert=>assert_equals( act = message->if_message~get_text( )
                                        exp = text ).
    cl_abap_unit_assert=>assert_equals( act = message->if_message~get_longtext( )
                                        exp = text ).
  ENDMETHOD.


  METHOD empty_input_is_empty.
    " Given no wrapper messages
    DATA messages TYPE zif_bfw_business_object=>messages.

    " When converting them for RAP
    DATA(rap_messages) = zcl_bfw_rap_message=>from_messages( messages ).

    " Then no RAP messages are produced
    cl_abap_unit_assert=>assert_initial( rap_messages ).
  ENDMETHOD.
ENDCLASS.
