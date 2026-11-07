"! Technical error in the access to a BOPF business object: unknown or ambiguous names, row types that do not fit
"! the node, business objects that are not classic BOPF, and BOPF contract violations (as previous exception)
CLASS zcx_bfw_access DEFINITION
  PUBLIC
  INHERITING FROM cx_no_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.

    CLASS-METHODS raise_unknown_business_object
      IMPORTING
        business_object TYPE csequence.

    "! BOPF-based RAP business objects are saved by RAP, not by the BOPF transaction manager
    CLASS-METHODS raise_rap_business_object
      IMPORTING
        business_object TYPE csequence.

    "! CDS-based business objects of the ABAP programming model for SAP Fiori are not supported
    CLASS-METHODS raise_cds_business_object
      IMPORTING
        business_object TYPE csequence.

    CLASS-METHODS raise_unknown_node
      IMPORTING
        node            TYPE csequence
        business_object TYPE csequence.

    "! The node name exists more than once, e.g. inside several dependent objects
    CLASS-METHODS raise_ambiguous_node
      IMPORTING
        node            TYPE csequence
        business_object TYPE csequence.

    CLASS-METHODS raise_unknown_association
      IMPORTING
        association TYPE csequence
        node        TYPE csequence.

    CLASS-METHODS raise_unknown_alternative_key
      IMPORTING
        alternative_key TYPE csequence
        node            TYPE csequence.

    CLASS-METHODS raise_unknown_query
      IMPORTING
        query TYPE csequence
        node  TYPE csequence.

    "! The caller's row type has a component that the node structure does not have
    CLASS-METHODS raise_unknown_component
      IMPORTING
        component TYPE csequence
        node      TYPE csequence.

    CLASS-METHODS raise_unstructured_rows
      IMPORTING
        node TYPE csequence.

    CLASS-METHODS raise_missing_data_type
      IMPORTING
        node TYPE csequence.

    "! BOPF raised an exception; it becomes the previous exception
    CLASS-METHODS raise_bopf_error
      IMPORTING
        business_object TYPE csequence
        previous        TYPE REF TO cx_root.

    "! The caller's row type lacks a component that the call needs, e.g. KEY or PARENT_KEY
    CLASS-METHODS raise_missing_component
      IMPORTING
        node      TYPE csequence
        component TYPE csequence.

    CLASS-METHODS raise_unknown_action
      IMPORTING
        action TYPE csequence
        node   TYPE csequence.

    "! The BOPF transaction manager raised an exception; it becomes the previous exception
    CLASS-METHODS raise_transaction_error
      IMPORTING
        previous TYPE REF TO cx_root.

    "! BOPF rejected the save in the save phase of RAP, which RAP does not allow after CHECK_BEFORE_SAVE
    CLASS-METHODS raise_rap_save_rejected.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_bfw_access IMPLEMENTATION.

  METHOD raise_unknown_business_object.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e001(zbfw) WITH business_object.
  ENDMETHOD.


  METHOD raise_rap_business_object.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e002(zbfw) WITH business_object.
  ENDMETHOD.


  METHOD raise_cds_business_object.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e003(zbfw) WITH business_object.
  ENDMETHOD.


  METHOD raise_unknown_node.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e004(zbfw) WITH node business_object.
  ENDMETHOD.


  METHOD raise_ambiguous_node.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e005(zbfw) WITH node business_object.
  ENDMETHOD.


  METHOD raise_unknown_association.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e006(zbfw) WITH association node.
  ENDMETHOD.


  METHOD raise_unknown_alternative_key.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e007(zbfw) WITH alternative_key node.
  ENDMETHOD.


  METHOD raise_unknown_query.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e008(zbfw) WITH query node.
  ENDMETHOD.


  METHOD raise_unknown_component.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e009(zbfw) WITH component node.
  ENDMETHOD.


  METHOD raise_unstructured_rows.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e010(zbfw) WITH node.
  ENDMETHOD.


  METHOD raise_missing_data_type.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e011(zbfw) WITH node.
  ENDMETHOD.


  METHOD raise_bopf_error.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e012(zbfw) WITH business_object
      EXPORTING previous = previous.
  ENDMETHOD.


  METHOD raise_missing_component.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e013(zbfw) WITH node component.
  ENDMETHOD.


  METHOD raise_unknown_action.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e014(zbfw) WITH action node.
  ENDMETHOD.


  METHOD raise_transaction_error.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e015(zbfw)
      EXPORTING previous = previous.
  ENDMETHOD.


  METHOD raise_rap_save_rejected.
    RAISE EXCEPTION TYPE zcx_bfw_access MESSAGE e017(zbfw).
  ENDMETHOD.
ENDCLASS.
