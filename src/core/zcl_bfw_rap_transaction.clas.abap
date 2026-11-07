"! RAP transaction on the subordinate BOPF transaction manager, whose phases are mapped like in SAP's own adapter for
"! SADL. The state of the current transaction makes each phase run once.
CLASS zcl_bfw_rap_transaction DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_bfw_factory.

  PUBLIC SECTION.
    INTERFACES zif_bfw_rap_transaction.

    METHODS constructor
      IMPORTING
        transaction_manager TYPE REF TO /bobf/if_tra_slave_trans_mgr.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF phases,
        finalized         TYPE abap_bool,
        finalize_rejected TYPE abap_bool,
        checked           TYPE abap_bool,
        check_rejected    TYPE abap_bool,
        numbers_adjusted  TYPE abap_bool,
        saved             TYPE abap_bool,
      END OF phases.

    DATA transaction_manager TYPE REF TO /bobf/if_tra_slave_trans_mgr.
    DATA message_converter TYPE REF TO zcl_bfw_message_converter.
    DATA done TYPE phases.
    "! Changes of ADJUST_NUMBERS, which SAVE passes on to BOPF
    DATA number_changes TYPE REF TO /bobf/if_tra_change.
ENDCLASS.



CLASS zcl_bfw_rap_transaction IMPLEMENTATION.

  METHOD constructor.
    me->transaction_manager = transaction_manager.
    message_converter = NEW #( ).
  ENDMETHOD.


  METHOD zif_bfw_rap_transaction~finalize.
    CLEAR messages.
    rejected = done-finalize_rejected.
    IF done-finalized = abap_true.
      RETURN.
    ENDIF.

    TRY.
        transaction_manager->finalize( IMPORTING eo_message  = DATA(bopf_messages)
                                                 ev_rejected = rejected ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_transaction_error( violation ).
    ENDTRY.
    done-finalized = abap_true.
    done-finalize_rejected = rejected.
    messages = message_converter->convert( bopf_messages ).
  ENDMETHOD.


  METHOD zif_bfw_rap_transaction~check_before_save.
    CLEAR messages.
    rejected = done-check_rejected.
    IF done-checked = abap_true.
      RETURN.
    ENDIF.

    TRY.
        " All business objects are checked, so RAP can report every failed instance at once
        transaction_manager->check_before_save( EXPORTING iv_abort_first_rejected = abap_false
                                                IMPORTING eo_message              = DATA(bopf_messages)
                                                          ev_rejected             = rejected ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_transaction_error( violation ).
    ENDTRY.
    done-checked = abap_true.
    done-check_rejected = rejected.
    messages = message_converter->convert( bopf_messages ).
  ENDMETHOD.


  METHOD zif_bfw_rap_transaction~adjust_numbers.
    IF done-numbers_adjusted = abap_true.
      RETURN.
    ENDIF.

    TRY.
        transaction_manager->adjust_numbers( IMPORTING eo_change  = number_changes
                                                       eo_message = DATA(bopf_messages) ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_transaction_error( violation ).
    ENDTRY.
    done-numbers_adjusted = abap_true.
    result = message_converter->convert( bopf_messages ).
  ENDMETHOD.


  METHOD zif_bfw_rap_transaction~save.
    DATA is_rejected TYPE abap_bool.

    IF done-saved = abap_true.
      RETURN.
    ENDIF.
    " RAP calls ADJUST_NUMBERS only for business objects with late numbering, but BOPF needs it before every save
    IF done-numbers_adjusted = abap_false.
      result = zif_bfw_rap_transaction~adjust_numbers( ).
    ENDIF.

    TRY.
        transaction_manager->on_numbers_adjusted( EXPORTING io_change  = number_changes
                                                  IMPORTING eo_message = DATA(number_messages) ).
        transaction_manager->do_save( IMPORTING eo_message  = DATA(save_messages)
                                                ev_rejected = is_rejected ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_transaction_error( violation ).
    ENDTRY.
    IF is_rejected = abap_true.
      zcx_bfw_access=>raise_rap_save_rejected( ).
    ENDIF.
    done-saved = abap_true.
    result = VALUE #( BASE result
                      ( LINES OF message_converter->convert( number_messages ) )
                      ( LINES OF message_converter->convert( save_messages ) ) ).
  ENDMETHOD.


  METHOD zif_bfw_rap_transaction~cleanup.
    TRY.
        IF done-saved = abap_true.
          transaction_manager->after_successful_save( ).
        ELSE.
          " RAP rolls back itself; BOPF only discards its buffer
          transaction_manager->do_cleanup( iv_cleanup_mode          = /bobf/if_conf_c=>sc_cleanup_refresh
                                           iv_execute_rollback_work = abap_false ).
        ENDIF.
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_transaction_error( violation ).
    ENDTRY.
    CLEAR: done, number_changes.
  ENDMETHOD.


  METHOD zif_bfw_rap_transaction~cleanup_finalize.
    TRY.
        transaction_manager->after_failed_save( ).
      CATCH /bobf/cx_frw_contrct_violation INTO DATA(violation).
        zcx_bfw_access=>raise_transaction_error( violation ).
    ENDTRY.
    " The corrected changes go through all phases again
    CLEAR: done, number_changes.
  ENDMETHOD.
ENDCLASS.
