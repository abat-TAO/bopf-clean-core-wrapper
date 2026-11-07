CLASS ltcl_factory DEFINITION DEFERRED.
CLASS zcl_bfw_factory DEFINITION LOCAL FRIENDS ltcl_factory.

CLASS ltcl_business_object_double DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PUBLIC SECTION.
    INTERFACES zif_bfw_business_object PARTIALLY IMPLEMENTED.
ENDCLASS.

CLASS ltcl_transaction_double DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PUBLIC SECTION.
    INTERFACES zif_bfw_transaction PARTIALLY IMPLEMENTED.
ENDCLASS.

CLASS ltcl_factory DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS business_object_name TYPE string VALUE `/BOBF/DEMO_SALES_ORDER`.

    METHODS setup.
    METHODS teardown.
    METHODS same_name_returns_cached_bo FOR TESTING.
    METHODS injected_bo_replaces_cached_bo FOR TESTING.
    METHODS injected_transaction_returned FOR TESTING.
    METHODS reset_clears_cached_instances FOR TESTING.
    METHODS reset_removes_injected_doubles FOR TESTING.
    METHODS unknown_bo_raises_access FOR TESTING.
ENDCLASS.



CLASS ltcl_business_object_double IMPLEMENTATION.
ENDCLASS.



CLASS ltcl_transaction_double IMPLEMENTATION.
ENDCLASS.



CLASS ltcl_factory IMPLEMENTATION.

  METHOD setup.
    zcl_bfw_injector=>reset( ).
  ENDMETHOD.


  METHOD teardown.
    zcl_bfw_injector=>reset( ).
  ENDMETHOD.


  METHOD same_name_returns_cached_bo.
    " Given a cached instance without constructing a real BOPF service manager
    DATA(cached) = NEW ltcl_business_object_double( ).
    INSERT VALUE #( name = business_object_name instance = cached ) INTO TABLE zcl_bfw_factory=>business_objects.

    " When the same BO is requested with different name casing
    DATA(first) = zcl_bfw_factory=>get_business_object( business_object_name ).
    DATA(second) = zcl_bfw_factory=>get_business_object( to_lower( business_object_name ) ).

    " Then both lookups reuse the cached reference
    cl_abap_unit_assert=>assert_equals( act = first
                                        exp = cached ).
    cl_abap_unit_assert=>assert_equals( act = second
                                        exp = first ).
    cl_abap_unit_assert=>assert_equals( act = lines( zcl_bfw_factory=>business_objects )
                                        exp = 1 ).
  ENDMETHOD.


  METHOD injected_bo_replaces_cached_bo.
    " Given an existing cache entry and a replacement double
    INSERT VALUE #( name     = business_object_name
                    instance = NEW ltcl_business_object_double( ) ) INTO TABLE zcl_bfw_factory=>business_objects.
    DATA(double) = NEW ltcl_business_object_double( ).

    " When injecting with the lower-case form of the same name
    zcl_bfw_injector=>inject_business_object( name = to_lower( business_object_name )
                                            double = double ).

    " Then the public factory lookup returns the replacement
    cl_abap_unit_assert=>assert_equals( act = zcl_bfw_factory=>get_business_object( business_object_name )
                                        exp = double ).
    cl_abap_unit_assert=>assert_equals( act = lines( zcl_bfw_factory=>business_objects )
                                        exp = 1 ).
  ENDMETHOD.


  METHOD injected_transaction_returned.
    " Given an inert transaction double
    DATA(double) = NEW ltcl_transaction_double( ).

    " When injecting it into the factory
    zcl_bfw_injector=>inject_transaction( double ).

    " Then every lookup returns that transaction
    cl_abap_unit_assert=>assert_equals( act = zcl_bfw_factory=>get_transaction( )
                                        exp = double ).
    cl_abap_unit_assert=>assert_equals( act = zcl_bfw_factory=>get_transaction( )
                                        exp = double ).
  ENDMETHOD.


  METHOD reset_clears_cached_instances.
    " Given cached BO and transaction references with no real BOPF dependencies
    INSERT VALUE #( name     = business_object_name
                    instance = NEW ltcl_business_object_double( ) ) INTO TABLE zcl_bfw_factory=>business_objects.
    zcl_bfw_factory=>transaction = NEW ltcl_transaction_double( ).

    " When resetting the factory
    zcl_bfw_injector=>reset( ).

    " Then both caches are empty
    cl_abap_unit_assert=>assert_initial( zcl_bfw_factory=>business_objects ).
    cl_abap_unit_assert=>assert_not_bound( zcl_bfw_factory=>transaction ).
  ENDMETHOD.


  METHOD reset_removes_injected_doubles.
    " Given injected references, including a BO name that does not exist in the configuration
    zcl_bfw_injector=>inject_business_object( name = `ZBFW_NONEXISTENT_UNIT_TEST_BO`
                                            double = NEW ltcl_business_object_double( ) ).
    zcl_bfw_injector=>inject_transaction( NEW ltcl_transaction_double( ) ).

    " When resetting and requesting the injected name again
    zcl_bfw_injector=>reset( ).
    TRY.
        zcl_bfw_factory=>get_business_object( `ZBFW_NONEXISTENT_UNIT_TEST_BO` ).
      CATCH zcx_bfw_access.
        " Then no injected BO survives and the transaction reference is cleared
        cl_abap_unit_assert=>assert_initial( zcl_bfw_factory=>business_objects ).
        cl_abap_unit_assert=>assert_not_bound( zcl_bfw_factory=>transaction ).
        RETURN.
    ENDTRY.
    cl_abap_unit_assert=>fail( `Reset must remove the injected business object` ).
  ENDMETHOD.


  METHOD unknown_bo_raises_access.
    " Given an empty factory and a name absent from the BOPF configuration
    " When requesting the unknown business object
    TRY.
        zcl_bfw_factory=>get_business_object( `ZBFW_NONEXISTENT_UNIT_TEST_BO` ).
      CATCH zcx_bfw_access.
        " Then resolution fails without caching an instance
        cl_abap_unit_assert=>assert_initial( zcl_bfw_factory=>business_objects ).
        RETURN.
    ENDTRY.
    cl_abap_unit_assert=>fail( `An unknown business object must raise ZCX_BFW_ACCESS` ).
  ENDMETHOD.
ENDCLASS.
