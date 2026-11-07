"! Classic transaction on the BOPF transaction manager
CLASS zcl_bfw_transaction DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_bfw_factory.

  PUBLIC SECTION.
    INTERFACES zif_bfw_transaction.

    METHODS constructor
      IMPORTING
        transaction_manager TYPE REF TO /bobf/if_tra_transaction_mgr.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA transaction_manager TYPE REF TO /bobf/if_tra_transaction_mgr.
    DATA message_converter TYPE REF TO zcl_bfw_message_converter.
ENDCLASS.



CLASS zcl_bfw_transaction IMPLEMENTATION.

  METHOD constructor.
    me->transaction_manager = transaction_manager.
    message_converter = NEW #( ).
  ENDMETHOD.


  METHOD zif_bfw_transaction~save.
    TRY.
        transaction_manager->save( IMPORTING ev_rejected = DATA(is_rejected)
                                             eo_message  = DATA(bopf_messages) ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_transaction_error( violation ).
    ENDTRY.

    result = message_converter->convert( bopf_messages ).
    IF is_rejected = abap_false.
      RETURN.
    ENDIF.

    " The rejected changes stay in the buffer, so the next save would try them again
    zif_bfw_transaction~cleanup( ).
    RAISE EXCEPTION TYPE zcx_bfw_save_rejected MESSAGE e016(zbfw)
      EXPORTING messages = result.
  ENDMETHOD.


  METHOD zif_bfw_transaction~cleanup.
    transaction_manager->cleanup( ).
  ENDMETHOD.
ENDCLASS.
