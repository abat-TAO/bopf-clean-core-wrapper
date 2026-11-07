"! Transaction for RAP business objects whose implementation changes BOPF business objects through the wrapper. The
"! saver of the RAP business object calls each method in its phase of the same name, so BOPF saves its changes in the
"! RAP save sequence and RAP commits them. Each phase runs once per transaction, also when the savers of several RAP
"! business objects call it.
INTERFACE zif_bfw_rap_transaction
  PUBLIC.

  TYPES:
    "! Transactional contracts as RAP allows them in the saver phases; weak like in ZIF_BFW_BUSINESS_OBJECT
    BEGIN OF tx_contract,
      finalize          TYPE if_abap_tx_modify=>ty_weak,
      check_before_save TYPE if_abap_tx_read=>ty_weak,
      adjust_numbers    TYPE if_abap_tx_save=>ty_weak,
      save              TYPE if_abap_tx_save=>ty_weak,
      cleanup           TYPE if_abap_tx_read=>ty_weak,
      cleanup_finalize  TYPE if_abap_tx_modify=>ty_weak,
    END OF tx_contract.

  "! For FINALIZE: runs the BOPF determinations before the save
  "! @parameter rejected | BOPF refuses the save; the RAP saver reports its instances as failed
  METHODS finalize
    EXPORTING
      rejected TYPE abap_bool
      messages TYPE zif_bfw_business_object=>messages.

  "! For CHECK_BEFORE_SAVE: runs the BOPF validations of all changed business objects
  "! @parameter rejected | A validation failed; the RAP saver reports its instances as failed
  METHODS check_before_save
    EXPORTING
      rejected TYPE abap_bool
      messages TYPE zif_bfw_business_object=>messages.

  "! For ADJUST_NUMBERS, which RAP calls only for business objects with late numbering (otherwise SAVE does it): lets
  "! BOPF draw its final numbers
  METHODS adjust_numbers
    RETURNING
      VALUE(result) TYPE zif_bfw_business_object=>messages.

  "! For SAVE: writes the BOPF changes without a commit; RAP commits them. A rejection raises ZCX_BFW_ACCESS, because
  "! RAP does not allow a save to fail in this phase.
  METHODS save
    RETURNING
      VALUE(result) TYPE zif_bfw_business_object=>messages.

  "! For CLEANUP: ends the BOPF transaction after the save; without a save, e.g. after ROLLBACK ENTITIES, it discards
  "! the BOPF changes
  METHODS cleanup.

  "! For CLEANUP_FINALIZE: lets BOPF undo the effects of FINALIZE and CHECK_BEFORE_SAVE after a refused save, so the
  "! changes can be corrected and saved again
  METHODS cleanup_finalize.

ENDINTERFACE.
