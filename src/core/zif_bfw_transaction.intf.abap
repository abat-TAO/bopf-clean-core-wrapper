"! Classic transaction for callers in Standard ABAP such as reports and jobs: saves or discards all changes made
"! through the business objects of ZCL_BFW_FACTORY. Not for RAP implementations, whose save RAP controls.
INTERFACE zif_bfw_transaction
  PUBLIC.

  TYPES:
    "! Transactional contracts for the controlled SAP LUW: SAVE and CLEANUP commit or roll back, so RAP
    "! implementations and APIs with other contracts must not call them. Weak like in ZIF_BFW_BUSINESS_OBJECT.
    BEGIN OF tx_contract,
      save    TYPE if_abap_tx_surface=>ty_weak,
      cleanup TYPE if_abap_tx_surface=>ty_weak,
    END OF tx_contract.

  "! Saves all changes; BOPF commits them (COMMIT WORK). A rejected save discards all changes.
  "! @parameter result                | Messages of the save, e.g. warnings
  "! @raising   zcx_bfw_save_rejected | The save was rejected; the changes were discarded
  METHODS save
    RETURNING
      VALUE(result) TYPE zif_bfw_business_object=>messages
    RAISING
      zcx_bfw_save_rejected.

  "! Discards all changes that were not saved
  METHODS cleanup.

ENDINTERFACE.
