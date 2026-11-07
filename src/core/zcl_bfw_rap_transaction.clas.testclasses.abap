CLASS ltcl_rap_transaction DEFINITION DEFERRED.
CLASS zcl_bfw_rap_transaction DEFINITION LOCAL FRIENDS ltcl_rap_transaction.

CLASS ltcl_rap_contracts DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS classifies_interface_methods FOR TESTING.
ENDCLASS.

CLASS ltcl_number_changes DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PUBLIC SECTION.
    INTERFACES /bobf/if_tra_change PARTIALLY IMPLEMENTED.
ENDCLASS.

CLASS ltcl_slave_transaction_manager DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT
  FRIENDS ltcl_rap_transaction.

  PUBLIC SECTION.
    INTERFACES /bobf/if_tra_slave_trans_mgr PARTIALLY IMPLEMENTED.

  PRIVATE SECTION.
    DATA calls TYPE string_table.
    DATA finalize_rejected TYPE abap_bool.
    DATA check_rejected TYPE abap_bool.
    DATA save_rejected TYPE abap_bool.
    DATA abort_first_rejected TYPE abap_bool.
    DATA cleanup_mode LIKE /bobf/if_conf_c=>sc_cleanup_refresh.
    DATA execute_rollback_work TYPE abap_bool.
    DATA finalize_messages TYPE REF TO /bobf/if_frw_message.
    DATA check_messages TYPE REF TO /bobf/if_frw_message.
    DATA adjust_messages TYPE REF TO /bobf/if_frw_message.
    DATA number_messages TYPE REF TO /bobf/if_frw_message.
    DATA save_messages TYPE REF TO /bobf/if_frw_message.
    DATA number_changes TYPE REF TO /bobf/if_tra_change.
    DATA received_changes TYPE REF TO /bobf/if_tra_change.
    DATA violation_phase TYPE string.
    DATA violation TYPE REF TO /bobf/cx_frw_contrct_violation.

    METHODS record_call
      IMPORTING
        phase TYPE string
      RAISING
        /bobf/cx_frw_contrct_violation.
ENDCLASS.

CLASS ltcl_rap_transaction DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA transaction_manager TYPE REF TO ltcl_slave_transaction_manager.
    DATA transaction TYPE REF TO zif_bfw_rap_transaction.

    METHODS setup.
    METHODS create_transaction_fixture.
    METHODS create_messages
      IMPORTING
        phase         TYPE symsgv
      RETURNING
        VALUE(result) TYPE REF TO /bobf/if_frw_message.
    METHODS assert_phase_violation
      IMPORTING
        phase TYPE string.

    METHODS finalize_returns_result FOR TESTING.
    METHODS check_returns_result FOR TESTING.
    METHODS finalize_runs_once FOR TESTING.
    METHODS check_runs_once FOR TESTING.
    METHODS adjust_numbers_runs_once FOR TESTING.
    METHODS save_adjusts_numbers FOR TESTING.
    METHODS save_uses_adjusted_numbers FOR TESTING.
    METHODS save_runs_once FOR TESTING.
    METHODS rejected_save_raises_access FOR TESTING.
    METHODS cleanup_after_save FOR TESTING.
    METHODS cleanup_without_save FOR TESTING.
    METHODS cleanup_resets_phases FOR TESTING.
    METHODS cleanup_finalize_resets_phases FOR TESTING.
    METHODS contract_violations_wrapped FOR TESTING.
ENDCLASS.



CLASS ltcl_rap_contracts IMPLEMENTATION.

  METHOD classifies_interface_methods.
    DATA expected_contract TYPE LINE OF cl_abap_behvdescr=>tt_proc_contract.

    " Given the weak transactional contracts of the public RAP transaction interface
    DATA(expected_contracts) = VALUE cl_abap_behvdescr=>tt_proc_contract(
        ( proc = 'FINALIZE'          contract = cl_abap_behvdescr=>modify severity = cl_abap_behvdescr=>weak )
        ( proc = 'CHECK_BEFORE_SAVE' contract = cl_abap_behvdescr=>read   severity = cl_abap_behvdescr=>weak )
        ( proc = 'ADJUST_NUMBERS'    contract = cl_abap_behvdescr=>save   severity = cl_abap_behvdescr=>weak )
        ( proc = 'SAVE'              contract = cl_abap_behvdescr=>save   severity = cl_abap_behvdescr=>weak )
        ( proc = 'CLEANUP'           contract = cl_abap_behvdescr=>read   severity = cl_abap_behvdescr=>weak )
        ( proc = 'CLEANUP_FINALIZE'  contract = cl_abap_behvdescr=>modify severity = cl_abap_behvdescr=>weak ) ).

    " When inspecting the interface classification
    cl_abap_behvdescr=>get_contracts(
        EXPORTING name      = 'ZIF_BFW_RAP_TRANSACTION'
                  kind      = 'J'
        IMPORTING contracts = DATA(contracts) ).

    " Then all six methods have exactly the expected contract and weak severity, in any order
    cl_abap_unit_assert=>assert_equals( act = lines( contracts )
                                        exp = 6 ).
    LOOP AT expected_contracts INTO expected_contract.
      cl_abap_unit_assert=>assert_table_contains(
          line  = expected_contract
          table = contracts
          msg   = expected_contract-proc ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.



CLASS ltcl_number_changes IMPLEMENTATION.
ENDCLASS.



CLASS ltcl_slave_transaction_manager IMPLEMENTATION.

  METHOD record_call.
    INSERT phase INTO TABLE calls.
    IF phase = violation_phase.
      RAISE EXCEPTION violation.
    ENDIF.
  ENDMETHOD.


  METHOD /bobf/if_tra_slave_trans_mgr~finalize.
    record_call( `FINALIZE` ).
    ev_rejected = finalize_rejected.
    eo_message = finalize_messages.
  ENDMETHOD.


  METHOD /bobf/if_tra_slave_trans_mgr~check_before_save.
    record_call( `CHECK_BEFORE_SAVE` ).
    abort_first_rejected = iv_abort_first_rejected.
    ev_rejected = check_rejected.
    eo_message = check_messages.
  ENDMETHOD.


  METHOD /bobf/if_tra_slave_trans_mgr~adjust_numbers.
    record_call( `ADJUST_NUMBERS` ).
    eo_change = number_changes.
    eo_message = adjust_messages.
  ENDMETHOD.


  METHOD /bobf/if_tra_slave_trans_mgr~on_numbers_adjusted.
    record_call( `ON_NUMBERS_ADJUSTED` ).
    received_changes = io_change.
    eo_message = number_messages.
  ENDMETHOD.


  METHOD /bobf/if_tra_slave_trans_mgr~do_save.
    record_call( `DO_SAVE` ).
    ev_rejected = save_rejected.
    eo_message = save_messages.
  ENDMETHOD.


  METHOD /bobf/if_tra_slave_trans_mgr~after_successful_save.
    record_call( `AFTER_SUCCESSFUL_SAVE` ).
  ENDMETHOD.


  METHOD /bobf/if_tra_slave_trans_mgr~do_cleanup.
    record_call( `DO_CLEANUP` ).
    cleanup_mode = iv_cleanup_mode.
    execute_rollback_work = iv_execute_rollback_work.
  ENDMETHOD.


  METHOD /bobf/if_tra_slave_trans_mgr~after_failed_save.
    record_call( `AFTER_FAILED_SAVE` ).
  ENDMETHOD.
ENDCLASS.



CLASS ltcl_rap_transaction IMPLEMENTATION.

  METHOD setup.
    create_transaction_fixture( ).
  ENDMETHOD.


  METHOD create_transaction_fixture.
    transaction_manager = NEW #( ).
    transaction_manager->number_changes = NEW ltcl_number_changes( ).
    transaction = NEW zcl_bfw_rap_transaction( transaction_manager ).
  ENDMETHOD.


  METHOD create_messages.
    result = /bobf/cl_frw_factory=>get_message( ).
    result->add_message( VALUE #( msgty = 'W' msgid = 'ZBFW' msgno = '016' msgv1 = phase ) ).
  ENDMETHOD.


  METHOD finalize_returns_result.
    " Given a rejected finalization with a message from BOPF
    transaction_manager->finalize_rejected = abap_true.
    transaction_manager->finalize_messages = create_messages( 'FINALIZE' ).
    DATA(expected) = NEW zcl_bfw_message_converter( )->convert( transaction_manager->finalize_messages ).

    " When finalizing through the RAP transaction
    transaction->finalize( IMPORTING rejected = DATA(rejected)
                                     messages = DATA(messages) ).

    " Then the matching BOPF phase supplies the rejection and converted messages
    cl_abap_unit_assert=>assert_true( rejected ).
    cl_abap_unit_assert=>assert_equals( act = messages
                                        exp = expected ).
    cl_abap_unit_assert=>assert_equals( act = transaction_manager->calls
                                        exp = VALUE string_table( ( `FINALIZE` ) ) ).
  ENDMETHOD.


  METHOD check_returns_result.
    " Given a rejected check with a message and an initially enabled early-abort observation
    transaction_manager->check_rejected = abap_true.
    transaction_manager->abort_first_rejected = abap_true.
    transaction_manager->check_messages = create_messages( 'CHECK_BEFORE_SAVE' ).
    DATA(expected) = NEW zcl_bfw_message_converter( )->convert( transaction_manager->check_messages ).

    " When checking the RAP transaction before save
    transaction->check_before_save( IMPORTING rejected = DATA(rejected)
                                              messages = DATA(messages) ).

    " Then BOPF checks all business objects and supplies its rejection and converted messages
    cl_abap_unit_assert=>assert_true( rejected ).
    cl_abap_unit_assert=>assert_false( transaction_manager->abort_first_rejected ).
    cl_abap_unit_assert=>assert_equals( act = messages
                                        exp = expected ).
    cl_abap_unit_assert=>assert_equals( act = transaction_manager->calls
                                        exp = VALUE string_table( ( `CHECK_BEFORE_SAVE` ) ) ).
  ENDMETHOD.


  METHOD finalize_runs_once.
    " Given a rejected finalization whose messages have already been returned
    transaction_manager->finalize_rejected = abap_true.
    transaction_manager->finalize_messages = create_messages( 'FINALIZE' ).
    transaction->finalize( IMPORTING rejected = DATA(rejected)
                                     messages = DATA(messages) ).
    cl_abap_unit_assert=>assert_not_initial( messages ).
    transaction_manager->finalize_rejected = abap_false.
    rejected = abap_false.

    " When another saver finalizes the same transaction using the same output variables
    transaction->finalize( IMPORTING rejected = rejected
                                     messages = messages ).

    " Then the stored rejection survives, messages are cleared and BOPF is called only once
    cl_abap_unit_assert=>assert_true( rejected ).
    cl_abap_unit_assert=>assert_initial( messages ).
    cl_abap_unit_assert=>assert_equals( act = transaction_manager->calls
                                        exp = VALUE string_table( ( `FINALIZE` ) ) ).
  ENDMETHOD.


  METHOD check_runs_once.
    " Given a rejected check whose messages have already been returned
    transaction_manager->check_rejected = abap_true.
    transaction_manager->check_messages = create_messages( 'CHECK_BEFORE_SAVE' ).
    transaction->check_before_save( IMPORTING rejected = DATA(rejected)
                                              messages = DATA(messages) ).
    cl_abap_unit_assert=>assert_not_initial( messages ).
    transaction_manager->check_rejected = abap_false.
    rejected = abap_false.

    " When another saver checks the same transaction using the same output variables
    transaction->check_before_save( IMPORTING rejected = rejected
                                              messages = messages ).

    " Then the stored rejection survives, messages are cleared and BOPF is called only once
    cl_abap_unit_assert=>assert_true( rejected ).
    cl_abap_unit_assert=>assert_initial( messages ).
    cl_abap_unit_assert=>assert_equals( act = transaction_manager->calls
                                        exp = VALUE string_table( ( `CHECK_BEFORE_SAVE` ) ) ).
  ENDMETHOD.


  METHOD adjust_numbers_runs_once.
    " Given a numbering phase that reports a message
    transaction_manager->adjust_messages = create_messages( 'ADJUST_NUMBERS' ).
    DATA(expected) = NEW zcl_bfw_message_converter( )->convert( transaction_manager->adjust_messages ).

    " When adjusting numbers twice in one transaction
    DATA(first_messages) = transaction->adjust_numbers( ).
    DATA(second_messages) = transaction->adjust_numbers( ).

    " Then only the first call reaches BOPF and returns its converted message
    cl_abap_unit_assert=>assert_equals( act = first_messages
                                        exp = expected ).
    cl_abap_unit_assert=>assert_initial( second_messages ).
    cl_abap_unit_assert=>assert_equals( act = transaction_manager->calls
                                        exp = VALUE string_table( ( `ADJUST_NUMBERS` ) ) ).
  ENDMETHOD.


  METHOD save_adjusts_numbers.
    " Given distinct messages from numbering, its callback and saving without a prior numbering phase
    transaction_manager->adjust_messages = create_messages( 'ADJUST_NUMBERS' ).
    transaction_manager->number_messages = create_messages( 'ON_NUMBERS_ADJUSTED' ).
    transaction_manager->save_messages = create_messages( 'DO_SAVE' ).
    DATA(converter) = NEW zcl_bfw_message_converter( ).
    DATA(expected) = VALUE zif_bfw_business_object=>messages(
        ( LINES OF converter->convert( transaction_manager->adjust_messages ) )
        ( LINES OF converter->convert( transaction_manager->number_messages ) )
        ( LINES OF converter->convert( transaction_manager->save_messages ) ) ).

    " When saving directly
    DATA(messages) = transaction->save( ).

    " Then numbering precedes its callback and save, carrying the same bound change object and all messages
    cl_abap_unit_assert=>assert_equals(
        act = transaction_manager->calls
        exp = VALUE string_table( ( `ADJUST_NUMBERS` ) ( `ON_NUMBERS_ADJUSTED` ) ( `DO_SAVE` ) ) ).
    cl_abap_unit_assert=>assert_bound( transaction_manager->received_changes ).
    cl_abap_unit_assert=>assert_true(
        xsdbool( transaction_manager->received_changes = transaction_manager->number_changes ) ).
    cl_abap_unit_assert=>assert_equals( act = messages
                                        exp = expected ).
  ENDMETHOD.


  METHOD save_uses_adjusted_numbers.
    " Given numbering that has already returned its message and change object
    transaction_manager->adjust_messages = create_messages( 'ADJUST_NUMBERS' ).
    transaction_manager->number_messages = create_messages( 'ON_NUMBERS_ADJUSTED' ).
    transaction_manager->save_messages = create_messages( 'DO_SAVE' ).
    transaction->adjust_numbers( ).
    DATA(changes) = transaction_manager->number_changes.
    transaction_manager->number_changes = NEW ltcl_number_changes( ).
    DATA(converter) = NEW zcl_bfw_message_converter( ).
    DATA(expected) = VALUE zif_bfw_business_object=>messages(
        ( LINES OF converter->convert( transaction_manager->number_messages ) )
        ( LINES OF converter->convert( transaction_manager->save_messages ) ) ).

    " When saving after the explicit numbering phase
    DATA(messages) = transaction->save( ).

    " Then BOPF receives the original change object without numbering again or repeating its messages
    cl_abap_unit_assert=>assert_equals(
        act = transaction_manager->calls
        exp = VALUE string_table( ( `ADJUST_NUMBERS` ) ( `ON_NUMBERS_ADJUSTED` ) ( `DO_SAVE` ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( transaction_manager->received_changes = changes ) ).
    cl_abap_unit_assert=>assert_equals( act = messages
                                        exp = expected ).
  ENDMETHOD.


  METHOD save_runs_once.
    " Given a successful save that has already returned its message
    transaction_manager->save_messages = create_messages( 'DO_SAVE' ).
    DATA(messages) = transaction->save( ).
    cl_abap_unit_assert=>assert_not_initial( messages ).

    " When another saver saves the same transaction
    messages = transaction->save( ).

    " Then no BOPF phase or message is repeated
    cl_abap_unit_assert=>assert_initial( messages ).
    cl_abap_unit_assert=>assert_equals(
        act = transaction_manager->calls
        exp = VALUE string_table( ( `ADJUST_NUMBERS` ) ( `ON_NUMBERS_ADJUSTED` ) ( `DO_SAVE` ) ) ).
  ENDMETHOD.


  METHOD rejected_save_raises_access.
    " Given a BOPF manager that rejects DO_SAVE
    transaction_manager->save_rejected = abap_true.

    " When saving in the RAP save phase
    TRY.
        transaction->save( ).
      CATCH zcx_bfw_access INTO DATA(rejection).
        " Then the public exception identifies a save rejected too late for RAP
        cl_abap_unit_assert=>assert_equals( act = rejection->if_t100_message~t100key-msgid
                                            exp = 'ZBFW' ).
        cl_abap_unit_assert=>assert_equals( act = rejection->if_t100_message~t100key-msgno
                                            exp = '017' ).
        cl_abap_unit_assert=>assert_equals(
            act = transaction_manager->calls
            exp = VALUE string_table( ( `ADJUST_NUMBERS` ) ( `ON_NUMBERS_ADJUSTED` ) ( `DO_SAVE` ) ) ).
        RETURN.
    ENDTRY.
    cl_abap_unit_assert=>fail( `A rejected RAP save must raise ZCX_BFW_ACCESS` ).
  ENDMETHOD.


  METHOD cleanup_after_save.
    " Given a transaction saved successfully
    transaction->save( ).

    " When cleaning up after the save
    transaction->cleanup( ).

    " Then the successful-save callback ends the transaction
    cl_abap_unit_assert=>assert_equals(
        act = transaction_manager->calls
        exp = VALUE string_table( ( `ADJUST_NUMBERS` ) ( `ON_NUMBERS_ADJUSTED` ) ( `DO_SAVE` )
                                  ( `AFTER_SUCCESSFUL_SAVE` ) ) ).
  ENDMETHOD.


  METHOD cleanup_without_save.
    " Given an unsaved transaction and an initially enabled rollback observation
    transaction_manager->execute_rollback_work = abap_true.

    " When discarding its buffer
    transaction->cleanup( ).

    " Then BOPF refreshes its buffer and leaves rollback to RAP
    cl_abap_unit_assert=>assert_equals( act = transaction_manager->calls
                                        exp = VALUE string_table( ( `DO_CLEANUP` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = transaction_manager->cleanup_mode
                                        exp = /bobf/if_conf_c=>sc_cleanup_refresh ).
    cl_abap_unit_assert=>assert_false( transaction_manager->execute_rollback_work ).
  ENDMETHOD.


  METHOD cleanup_resets_phases.
    " Given all phases completed with stored finalization and check rejections
    transaction_manager->finalize_rejected = abap_true.
    transaction_manager->check_rejected = abap_true.
    transaction->finalize( ).
    transaction->check_before_save( ).
    transaction->save( ).

    " When cleanup ends the transaction and every phase is requested again
    transaction->cleanup( ).
    transaction_manager->finalize_rejected = abap_false.
    transaction_manager->check_rejected = abap_false.
    transaction_manager->number_changes = NEW ltcl_number_changes( ).
    transaction->finalize( IMPORTING rejected = DATA(finalize_rejected) ).
    transaction->check_before_save( IMPORTING rejected = DATA(check_rejected) ).
    transaction->save( ).

    " Then each phase runs again and the previous rejections and numbering state are gone
    cl_abap_unit_assert=>assert_false( finalize_rejected ).
    cl_abap_unit_assert=>assert_false( check_rejected ).
    cl_abap_unit_assert=>assert_true(
        xsdbool( transaction_manager->received_changes = transaction_manager->number_changes ) ).
    cl_abap_unit_assert=>assert_equals(
        act = transaction_manager->calls
        exp = VALUE string_table(
            ( `FINALIZE` ) ( `CHECK_BEFORE_SAVE` ) ( `ADJUST_NUMBERS` ) ( `ON_NUMBERS_ADJUSTED` ) ( `DO_SAVE` )
            ( `AFTER_SUCCESSFUL_SAVE` )
            ( `FINALIZE` ) ( `CHECK_BEFORE_SAVE` ) ( `ADJUST_NUMBERS` ) ( `ON_NUMBERS_ADJUSTED` ) ( `DO_SAVE` ) ) ).
  ENDMETHOD.


  METHOD cleanup_finalize_resets_phases.
    " Given a refused transaction that has also adjusted numbers
    transaction_manager->finalize_rejected = abap_true.
    transaction_manager->check_rejected = abap_true.
    transaction->finalize( ).
    transaction->check_before_save( ).
    transaction->adjust_numbers( ).

    " When finalization is cleaned up and corrected changes go through the phases again
    transaction->cleanup_finalize( ).
    transaction_manager->finalize_rejected = abap_false.
    transaction_manager->check_rejected = abap_false.
    transaction_manager->number_changes = NEW ltcl_number_changes( ).
    transaction->finalize( IMPORTING rejected = DATA(finalize_rejected) ).
    transaction->check_before_save( IMPORTING rejected = DATA(check_rejected) ).
    transaction->save( ).

    " Then failed-save cleanup resets the phase flags, rejections and numbering state
    cl_abap_unit_assert=>assert_false( finalize_rejected ).
    cl_abap_unit_assert=>assert_false( check_rejected ).
    cl_abap_unit_assert=>assert_true(
        xsdbool( transaction_manager->received_changes = transaction_manager->number_changes ) ).
    cl_abap_unit_assert=>assert_equals(
        act = transaction_manager->calls
        exp = VALUE string_table(
            ( `FINALIZE` ) ( `CHECK_BEFORE_SAVE` ) ( `ADJUST_NUMBERS` ) ( `AFTER_FAILED_SAVE` )
            ( `FINALIZE` ) ( `CHECK_BEFORE_SAVE` ) ( `ADJUST_NUMBERS` ) ( `ON_NUMBERS_ADJUSTED` ) ( `DO_SAVE` ) ) ).
  ENDMETHOD.


  METHOD contract_violations_wrapped.
    DATA phase TYPE string.

    " Given every BOPF callback that can raise a contract violation
    DATA(phases) = VALUE string_table(
        ( `FINALIZE` ) ( `CHECK_BEFORE_SAVE` ) ( `ADJUST_NUMBERS` ) ( `ON_NUMBERS_ADJUSTED` )
        ( `DO_SAVE` ) ( `AFTER_SUCCESSFUL_SAVE` ) ( `DO_CLEANUP` ) ( `AFTER_FAILED_SAVE` ) ).

    " When each callback raises its original exception
    LOOP AT phases INTO phase.
      create_transaction_fixture( ).

      " Then every wrapper entry point exposes ZCX_BFW_ACCESS with the original cause
      assert_phase_violation( phase ).
    ENDLOOP.
  ENDMETHOD.


  METHOD assert_phase_violation.
    transaction_manager->violation = /bobf/cx_frw_contrct_violation=>create_with(
        NEW /bobf/cx_frw_int_cntrct_violtn( ) ).
    IF phase = `AFTER_SUCCESSFUL_SAVE`.
      transaction->save( ).
    ENDIF.
    transaction_manager->violation_phase = phase.
    TRY.
        CASE phase.
          WHEN `FINALIZE`.
            transaction->finalize( ).
          WHEN `CHECK_BEFORE_SAVE`.
            transaction->check_before_save( ).
          WHEN `ADJUST_NUMBERS`.
            transaction->adjust_numbers( ).
          WHEN `ON_NUMBERS_ADJUSTED` OR `DO_SAVE`.
            transaction->save( ).
          WHEN `AFTER_SUCCESSFUL_SAVE` OR `DO_CLEANUP`.
            transaction->cleanup( ).
          WHEN `AFTER_FAILED_SAVE`.
            transaction->cleanup_finalize( ).
        ENDCASE.
      CATCH zcx_bfw_access INTO DATA(access_error).
        cl_abap_unit_assert=>assert_equals( act = access_error->if_t100_message~t100key-msgid
                                            exp = 'ZBFW'
                                            msg = phase ).
        cl_abap_unit_assert=>assert_equals( act = access_error->if_t100_message~t100key-msgno
                                            exp = '015'
                                            msg = phase ).
        cl_abap_unit_assert=>assert_true( act = xsdbool( access_error->previous = transaction_manager->violation )
                                          msg = phase ).
        RETURN.
    ENDTRY.
    cl_abap_unit_assert=>fail( |{ phase } must wrap the BOPF contract violation| ).
  ENDMETHOD.
ENDCLASS.
