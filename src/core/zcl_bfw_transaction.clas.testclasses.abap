CLASS ltcl_transaction DEFINITION DEFERRED.
CLASS zcl_bfw_transaction DEFINITION LOCAL FRIENDS ltcl_transaction.

CLASS ltcl_transaction_contracts DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS classifies_interface_methods FOR TESTING.
ENDCLASS.

CLASS ltcl_transaction_manager DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT
  FRIENDS ltcl_transaction.

  PUBLIC SECTION.
    INTERFACES /bobf/if_tra_transaction_mgr PARTIALLY IMPLEMENTED.

  PRIVATE SECTION.
    DATA is_rejected TYPE abap_bool.
    DATA messages TYPE REF TO /bobf/if_frw_message.
    DATA calls TYPE string_table.
ENDCLASS.

CLASS ltcl_transaction DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA transaction_manager TYPE REF TO ltcl_transaction_manager.
    DATA transaction TYPE REF TO zif_bfw_transaction.

    METHODS setup.
    METHODS save_returns_messages FOR TESTING RAISING zcx_bfw_save_rejected.
    METHODS rejected_save_cleans_up FOR TESTING.
    METHODS rejected_save_keeps_messages FOR TESTING.
ENDCLASS.



CLASS ltcl_transaction_contracts IMPLEMENTATION.

  METHOD classifies_interface_methods.
    DATA expected_contract TYPE LINE OF cl_abap_behvdescr=>tt_proc_contract.

    " Given the weak surface contracts of the public transaction interface
    DATA(expected_contracts) = VALUE cl_abap_behvdescr=>tt_proc_contract(
        ( proc = 'SAVE'    contract = cl_abap_behvdescr=>surface severity = cl_abap_behvdescr=>weak )
        ( proc = 'CLEANUP' contract = cl_abap_behvdescr=>surface severity = cl_abap_behvdescr=>weak ) ).

    " When inspecting the interface classification
    cl_abap_behvdescr=>get_contracts(
        EXPORTING name      = 'ZIF_BFW_TRANSACTION'
                  kind      = 'J'
        IMPORTING contracts = DATA(contracts) ).

    " Then both methods have exactly the expected contract and weak severity, in any order
    cl_abap_unit_assert=>assert_equals( act = lines( contracts )
                                        exp = 2 ).
    LOOP AT expected_contracts INTO expected_contract.
      cl_abap_unit_assert=>assert_table_contains(
          line  = expected_contract
          table = contracts
          msg   = expected_contract-proc ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.



CLASS ltcl_transaction_manager IMPLEMENTATION.

  METHOD /bobf/if_tra_transaction_mgr~save.
    INSERT `SAVE` INTO TABLE calls.
    ev_rejected = is_rejected.
    eo_message = messages.
  ENDMETHOD.


  METHOD /bobf/if_tra_transaction_mgr~cleanup.
    INSERT `CLEANUP` INTO TABLE calls.
  ENDMETHOD.
ENDCLASS.



CLASS ltcl_transaction IMPLEMENTATION.

  METHOD setup.
    transaction_manager = NEW #( ).
    transaction_manager->messages = /bobf/cl_frw_factory=>get_message( ).
    transaction_manager->messages->add_message(
        VALUE #( msgty = 'W' msgid = 'ZBFW' msgno = '016' ) ).
    transaction = NEW zcl_bfw_transaction( transaction_manager ).
  ENDMETHOD.


  METHOD save_returns_messages.
    " Given a successful save with a warning from the transaction manager
    DATA(expected) = NEW zcl_bfw_message_converter( )->convert( transaction_manager->messages ).

    " When saving through the wrapper
    DATA(messages) = transaction->save( ).

    " Then the messages survive and successful changes are not cleaned up
    cl_abap_unit_assert=>assert_equals( act = messages
                                        exp = expected ).
    cl_abap_unit_assert=>assert_equals( act = transaction_manager->calls
                                        exp = VALUE string_table( ( `SAVE` ) ) ).
  ENDMETHOD.


  METHOD rejected_save_cleans_up.
    " Given a transaction manager that rejects the save
    transaction_manager->is_rejected = abap_true.

    " When the save is rejected
    TRY.
        transaction->save( ).
      CATCH zcx_bfw_save_rejected.
        " Then cleanup follows the save before the rejection reaches the caller
        cl_abap_unit_assert=>assert_equals(
            act = transaction_manager->calls
            exp = VALUE string_table( ( `SAVE` ) ( `CLEANUP` ) ) ).
        RETURN.
    ENDTRY.
    cl_abap_unit_assert=>fail( `A rejected save must raise ZCX_BFW_SAVE_REJECTED` ).
  ENDMETHOD.


  METHOD rejected_save_keeps_messages.
    " Given an error message from a rejected save
    transaction_manager->is_rejected = abap_true.
    transaction_manager->messages = /bobf/cl_frw_factory=>get_message( ).
    transaction_manager->messages->add_message(
        VALUE #( msgty = 'E' msgid = 'ZBFW' msgno = '016' ) ).
    DATA(expected) = NEW zcl_bfw_message_converter( )->convert( transaction_manager->messages ).

    " When the wrapper raises the rejection
    TRY.
        transaction->save( ).
      CATCH zcx_bfw_save_rejected INTO DATA(rejection).
        " Then the exception retains the converted messages
        cl_abap_unit_assert=>assert_equals( act = rejection->get_messages( )
                                            exp = expected ).
        RETURN.
    ENDTRY.
    cl_abap_unit_assert=>fail( `A rejected save must carry its messages` ).
  ENDMETHOD.
ENDCLASS.
