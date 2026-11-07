"! Entry point of the BOPF wrapper: returns the business object engine for a classic BOPF business object by name.
"! One engine per business object and one transaction of each kind are kept for the session; ZCL_BFW_INJECTOR replaces
"! them by test doubles.
CLASS zcl_bfw_factory DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_bfw_injector.

  PUBLIC SECTION.
    "! @parameter name | Name of the business object, e.g. /BOBF/DEMO_SALES_ORDER
    CLASS-METHODS get_business_object
      IMPORTING
        name          TYPE csequence
      RETURNING
        VALUE(result) TYPE REF TO zif_bfw_business_object.

    "! Classic transaction for all business objects: save and cleanup
    CLASS-METHODS get_transaction
      RETURNING
        VALUE(result) TYPE REF TO zif_bfw_transaction.

    "! Transaction for RAP business objects: their saver calls it in the RAP save sequence, RAP commits
    CLASS-METHODS get_rap_transaction
      RETURNING
        VALUE(result) TYPE REF TO zif_bfw_rap_transaction.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF business_object_entry,
        name     TYPE string,
        instance TYPE REF TO zif_bfw_business_object,
      END OF business_object_entry,
      business_object_entries TYPE HASHED TABLE OF business_object_entry WITH UNIQUE KEY name.

    CLASS-DATA business_objects TYPE business_object_entries.
    CLASS-DATA transaction TYPE REF TO zif_bfw_transaction.
    CLASS-DATA rap_transaction TYPE REF TO zif_bfw_rap_transaction.

    CLASS-METHODS create_business_object
      IMPORTING
        name          TYPE string
      RETURNING
        VALUE(result) TYPE REF TO zif_bfw_business_object.
ENDCLASS.



CLASS zcl_bfw_factory IMPLEMENTATION.

  METHOD get_business_object.
    DATA(upper_name) = to_upper( name ).
    result = VALUE #( business_objects[ name = upper_name ]-instance OPTIONAL ).
    IF result IS BOUND.
      RETURN.
    ENDIF.

    result = create_business_object( upper_name ).
    INSERT VALUE #( name     = upper_name
                    instance = result ) INTO TABLE business_objects.
  ENDMETHOD.


  METHOD get_transaction.
    IF transaction IS NOT BOUND.
      transaction = NEW zcl_bfw_transaction( /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager( ) ).
    ENDIF.
    result = transaction.
  ENDMETHOD.


  METHOD get_rap_transaction.
    IF rap_transaction IS NOT BOUND.
      rap_transaction = NEW zcl_bfw_rap_transaction(
                              /bobf/cl_tra_trans_mgr_factory=>get_slave_transaction_manager( ) ).
    ENDIF.
    result = rap_transaction.
  ENDMETHOD.


  METHOD create_business_object.
    DATA(business_object_key) = /bobf/cl_frw_factory=>query_bo( CONV #( name ) ).
    IF business_object_key IS INITIAL.
      zcx_bfw_access=>raise_unknown_business_object( name ).
    ENDIF.

    TRY.
        " Loading the configuration of a RAP business object without draft context dumps, so this check comes first
        IF /bobf/cl_frw_factory=>is_rap_bo( business_object_key ) = abap_true.
          zcx_bfw_access=>raise_rap_business_object( name ).
        ENDIF.
        DATA(configuration) = /bobf/cl_frw_factory=>get_configuration( business_object_key ).
        IF configuration->ms_obj-object_model_generated = abap_true.
          zcx_bfw_access=>raise_cds_business_object( name ).
        ENDIF.
        result = NEW zcl_bfw_business_object(
                       business_object_key = business_object_key
                       service_manager     = /bobf/cl_tra_serv_mgr_factory=>get_service_manager( business_object_key )
                       configuration       = configuration ).
      CATCH /bobf/cx_frw /bobf/cx_frw_contrct_violation INTO DATA(error).
        zcx_bfw_access=>raise_bopf_error( business_object = name
                                          previous        = error ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
