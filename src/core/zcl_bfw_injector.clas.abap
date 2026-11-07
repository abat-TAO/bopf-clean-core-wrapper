"! Replaces the business objects and the transaction of ZCL_BFW_FACTORY by test doubles in unit tests of consumers
CLASS zcl_bfw_injector DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  FOR TESTING.

  PUBLIC SECTION.
    "! @parameter name   | Name of the business object, as passed to ZCL_BFW_FACTORY=&gt;GET_BUSINESS_OBJECT
    "! @parameter double | Test double that the factory returns from now on
    CLASS-METHODS inject_business_object
      IMPORTING
        name   TYPE csequence
        double TYPE REF TO zif_bfw_business_object.

    "! @parameter double | Test double that ZCL_BFW_FACTORY=&gt;GET_TRANSACTION returns from now on
    CLASS-METHODS inject_transaction
      IMPORTING
        double TYPE REF TO zif_bfw_transaction.

    "! @parameter double | Test double that ZCL_BFW_FACTORY=&gt;GET_RAP_TRANSACTION returns from now on
    CLASS-METHODS inject_rap_transaction
      IMPORTING
        double TYPE REF TO zif_bfw_rap_transaction.

    "! Removes all doubles and cached instances from the factory
    CLASS-METHODS reset.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_bfw_injector IMPLEMENTATION.

  METHOD inject_business_object.
    DATA(upper_name) = to_upper( name ).
    DELETE TABLE zcl_bfw_factory=>business_objects WITH TABLE KEY name = upper_name.
    INSERT VALUE #( name     = upper_name
                    instance = double ) INTO TABLE zcl_bfw_factory=>business_objects.
  ENDMETHOD.


  METHOD inject_transaction.
    zcl_bfw_factory=>transaction = double.
  ENDMETHOD.


  METHOD inject_rap_transaction.
    zcl_bfw_factory=>rap_transaction = double.
  ENDMETHOD.


  METHOD reset.
    CLEAR: zcl_bfw_factory=>business_objects,
           zcl_bfw_factory=>transaction,
           zcl_bfw_factory=>rap_transaction.
  ENDMETHOD.
ENDCLASS.
