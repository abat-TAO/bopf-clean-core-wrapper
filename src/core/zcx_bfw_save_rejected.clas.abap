"! The save was rejected, e.g. by a validation; all changes of the transaction were discarded
CLASS zcx_bfw_save_rejected DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.

    METHODS constructor
      IMPORTING
        textid   LIKE if_t100_message=>t100key OPTIONAL
        previous LIKE previous OPTIONAL
        messages TYPE zif_bfw_business_object=>messages OPTIONAL.

    "! Messages of the rejected save, e.g. of the validations that failed
    METHODS get_messages
      RETURNING
        VALUE(result) TYPE zif_bfw_business_object=>messages.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA messages TYPE zif_bfw_business_object=>messages.
ENDCLASS.



CLASS zcx_bfw_save_rejected IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->messages = messages.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.


  METHOD get_messages.
    result = messages.
  ENDMETHOD.
ENDCLASS.
