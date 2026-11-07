"! Writes the facade model of ZCL_BFW_FACADE_GENERATOR as a global class with the class builder (inactive version)
"! and activates it. An existing class is replaced only if the generator wrote it. Development tool: it uses
"! classic and internal workbench APIs.
CLASS zcl_bfw_facade_writer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Source of a method implementation of an existing class: the active version, otherwise the inactive version;
    "! empty if the class or the method does not exist
    METHODS read_method_source
      IMPORTING
        class_name    TYPE csequence
        method_name   TYPE csequence
      RETURNING
        VALUE(result) TYPE string_table.

    "! @parameter package   | Package of a new class; an existing class keeps its package
    "! @parameter transport | Workbench request; not needed for local packages ($...)
    "! @parameter result    | Why nothing was written, or the activation errors; the inactive version then stays
    METHODS write
      IMPORTING
        facade        TYPE zcl_bfw_facade_generator=>facade
        package       TYPE csequence
        transport     TYPE csequence
      RETURNING
        VALUE(result) TYPE string_table.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
      "! Domain values of the class builder (domains SEOCATEGRY, SEOEXPOSE, SEOSTATE, SEOMTDDECL, SEOMTDTYPE,
      "! SEOPARDECL, SEOPARPASS, SEOTYPTYPE, SEOATTDECL, SEOCMPTYPE)
      BEGIN OF class_builder,
        category_general   TYPE vseoclass-category VALUE '00',
        exposure_private   TYPE vseoclass-exposure VALUE '0',
        exposure_public    TYPE vseoclass-exposure VALUE '2',
        state_implemented  TYPE vseoclass-state VALUE '1',
        version_inactive   TYPE seoversion VALUE '0',
        instance_method    TYPE vseomethod-mtddecltyp VALUE '0',
        static_method      TYPE vseomethod-mtddecltyp VALUE '1',
        normal_method      TYPE vseomethod-mtdtype VALUE '0',
        constructor        TYPE vseomethod-mtdtype VALUE '2',
        importing          TYPE vseoparam-pardecltyp VALUE '0',
        exporting          TYPE vseoparam-pardecltyp VALUE '1',
        changing           TYPE vseoparam-pardecltyp VALUE '2',
        returning          TYPE vseoparam-pardecltyp VALUE '3',
        by_value           TYPE vseoparam-parpasstyp VALUE '0',
        by_reference       TYPE vseoparam-parpasstyp VALUE '1',
        type_reference     TYPE vseoparam-typtype VALUE '1',
        object_reference   TYPE vseoattrib-typtype VALUE '3',
        instance_attribute TYPE vseoattrib-attdecltyp VALUE '0',
        method_component   TYPE vseoparam-cmptype VALUE '1',
      END OF class_builder.

    "! Error if the class exists and is not a facade of the generator
    METHODS check_replacement
      IMPORTING
        class_name    TYPE seoclsname
      RETURNING
        VALUE(result) TYPE string_table.

    METHODS create_class
      IMPORTING
        facade        TYPE zcl_bfw_facade_generator=>facade
        package       TYPE csequence
        transport     TYPE csequence
      RETURNING
        VALUE(result) TYPE string_table.

    METHODS activate
      IMPORTING
        class_name    TYPE seoclsname
      RETURNING
        VALUE(result) TYPE string_table.

    METHODS get_methods
      IMPORTING
        facade        TYPE zcl_bfw_facade_generator=>facade
      RETURNING
        VALUE(result) TYPE seoo_methods_r.

    METHODS get_parameters
      IMPORTING
        facade        TYPE zcl_bfw_facade_generator=>facade
      RETURNING
        VALUE(result) TYPE seos_parameters_r.

    METHODS get_attributes
      IMPORTING
        facade        TYPE zcl_bfw_facade_generator=>facade
      RETURNING
        VALUE(result) TYPE seoo_attributes_r.

    METHODS get_method_sources
      IMPORTING
        facade        TYPE zcl_bfw_facade_generator=>facade
      RETURNING
        VALUE(result) TYPE seo_method_source_table.

    METHODS to_declaration_type
      IMPORTING
        direction     TYPE zcl_bfw_facade_generator=>method_parameter-direction
      RETURNING
        VALUE(result) TYPE vseoparam-pardecltyp.
ENDCLASS.



CLASS zcl_bfw_facade_writer IMPLEMENTATION.

  METHOD read_method_source.
    DATA(method) = xco_cp_abap=>class( CONV #( class_name ) )->implementation->method( CONV #( method_name ) ).
    TRY.
        result = method->content( )->get_source( ).
      CATCH cx_xco_runtime_exception.
        " A class can exist only as an inactive version, e.g. after a failed activation
        TRY.
            result = method->content( io_version = xco_cp_abap_objects=>version->inactive )->get_source( ).
          CATCH cx_xco_runtime_exception.
            CLEAR result.
        ENDTRY.
    ENDTRY.
  ENDMETHOD.


  METHOD write.
    DATA(class_name) = CONV seoclsname( facade-class_name ).
    IF package IS INITIAL.
      INSERT `A package is needed` INTO TABLE result.
    ELSEIF package NP '$*' AND transport IS INITIAL.
      INSERT |Package { package } needs a transport request| INTO TABLE result.
    ENDIF.
    INSERT LINES OF check_replacement( class_name ) INTO TABLE result.
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    result = create_class( facade    = facade
                           package   = package
                           transport = transport ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.
    result = activate( class_name ).
  ENDMETHOD.


  METHOD check_replacement.
    DATA(class) = xco_cp_abap=>class( class_name ).
    IF class->exists( ) = abap_false
        AND class->exists( io_version = xco_cp_abap_objects=>version->inactive ) = abap_false.
      RETURN.
    ENDIF.

    DATA(selection_source) = read_method_source( class_name  = class_name
                                                 method_name = `GET_SELECTION` ).
    IF NEW zcl_bfw_facade_generator( )->is_generated_source( selection_source ) = abap_false.
      INSERT |Class { class_name } exists and was not generated by ZBFW_FACADE_GENERATOR; nothing was written|
             INTO TABLE result.
    ENDIF.
  ENDMETHOD.


  METHOD create_class.
    DATA message_text TYPE string.

    " UNICODE X = ABAP language version Standard ABAP
    DATA(class) = VALUE vseoclass( clsname   = facade-class_name
                                   langu     = sy-langu
                                   descript  = facade-description
                                   category  = class_builder-category_general
                                   exposure  = class_builder-exposure_public
                                   state     = class_builder-state_implemented
                                   clsfinal  = abap_true
                                   clsccincl = abap_true
                                   fixpt     = abap_true
                                   unicode   = abap_true ).
    DATA(methods) = get_methods( facade ).
    DATA(parameters) = get_parameters( facade ).
    DATA(attributes) = get_attributes( facade ).
    DATA(method_sources) = get_method_sources( facade ).
    DATA(request) = CONV trkorr( transport ).
    DATA(target_package) = CONV devclass( package ).

    " Overwriting deletes and recreates the class, so methods no longer in the selection disappear; the inactive
    " version leaves the active facade working until the activation succeeds
    CALL FUNCTION 'SEO_CLASS_CREATE_COMPLETE'
      EXPORTING
        corrnr          = request
        devclass        = target_package
        version         = class_builder-version_inactive
        overwrite       = abap_true
        method_sources  = method_sources
        suppress_dialog = abap_true
      CHANGING
        class           = class
        methods         = methods
        parameters      = parameters
        attributes      = attributes
      EXCEPTIONS
        existing        = 1
        is_interface    = 2
        db_error        = 3
        component_error = 4
        no_access       = 5
        other           = 6
        OTHERS          = 7.
    DATA(return_code) = sy-subrc.
    IF return_code = 0.
      RETURN.
    ENDIF.

    IF sy-msgid IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO message_text.
    ENDIF.
    INSERT |The class builder rejected { facade-class_name } (return code { return_code }): { message_text }|
           INTO TABLE result.
  ENDMETHOD.


  METHOD activate.
    DATA objects TYPE STANDARD TABLE OF dwinactiv WITH EMPTY KEY.
    DATA checklist TYPE REF TO cl_wb_checklist.
    DATA error_count TYPE i.
    DATA message_lines TYPE rsfb_source.
    DATA line TYPE i.

    objects = VALUE #( ( object   = 'CLAS'
                         obj_name = class_name ) ).
    CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
      EXPORTING
        activate_ddic_objects  = abap_false
        with_popup             = abap_false
        ui_decoupled           = abap_true
      IMPORTING
        p_checklist            = checklist
      TABLES
        objects                = objects
      EXCEPTIONS
        excecution_error       = 1
        cancelled              = 2
        insert_into_corr_error = 3
        OTHERS                 = 4.
    DATA(return_code) = sy-subrc.

    IF checklist IS BOUND.
      checklist->get_message_number( IMPORTING p_error_number = error_count ).
      DO error_count TIMES.
        checklist->get_error_message(
          EXPORTING
            p_index         = sy-index
          IMPORTING
            p_message_text  = message_lines
            p_line          = line
          EXCEPTIONS
            entry_not_found = 1
            OTHERS          = 2 ).
        IF sy-subrc = 0.
          INSERT |Line { line }: { concat_lines_of( table = message_lines
                                                    sep   = ` ` ) }| INTO TABLE result.
        ENDIF.
      ENDDO.
    ENDIF.
    IF return_code <> 0 AND result IS INITIAL.
      INSERT |The activation of { class_name } failed (return code { return_code }); the inactive version stays|
             INTO TABLE result.
    ENDIF.
  ENDMETHOD.


  METHOD get_methods.
    result = VALUE #( FOR method IN facade-methods
                      ( clsname    = facade-class_name
                        cmpname    = method-name
                        langu      = sy-langu
                        exposure   = class_builder-exposure_public
                        state      = class_builder-state_implemented
                        mtddecltyp = COND #( WHEN method-is_static = abap_true
                                             THEN class_builder-static_method
                                             ELSE class_builder-instance_method )
                        mtdtype    = COND #( WHEN method-name = `CONSTRUCTOR`
                                             THEN class_builder-constructor
                                             ELSE class_builder-normal_method ) ) ).
  ENDMETHOD.


  METHOD get_parameters.
    LOOP AT facade-methods ASSIGNING FIELD-SYMBOL(<method>).
      LOOP AT <method>-parameters ASSIGNING FIELD-SYMBOL(<parameter>).
        INSERT VALUE #( clsname    = facade-class_name
                        cmpname    = <method>-name
                        sconame    = <parameter>-name
                        langu      = sy-langu
                        cmptype    = class_builder-method_component
                        pardecltyp = to_declaration_type( <parameter>-direction )
                        parpasstyp = COND #( WHEN <parameter>-direction = zcl_bfw_facade_generator=>directions-returning
                                             THEN class_builder-by_value
                                             ELSE class_builder-by_reference )
                        typtype    = class_builder-type_reference
                        type       = <parameter>-type_name
                        paroptionl = <parameter>-is_optional
                        parvalue   = <parameter>-default_value ) INTO TABLE result.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_attributes.
    result = VALUE #( FOR attribute IN facade-attributes
                      ( clsname    = facade-class_name
                        cmpname    = attribute-name
                        langu      = sy-langu
                        exposure   = class_builder-exposure_private
                        state      = class_builder-state_implemented
                        attdecltyp = class_builder-instance_attribute
                        typtype    = class_builder-object_reference
                        type       = attribute-interface_name ) ).
  ENDMETHOD.


  METHOD get_method_sources.
    result = VALUE #( FOR method IN facade-methods
                      ( cpdname = method-name
                        source  = method-source ) ).
  ENDMETHOD.


  METHOD to_declaration_type.
    result = SWITCH #( direction
                       WHEN zcl_bfw_facade_generator=>directions-exporting THEN class_builder-exporting
                       WHEN zcl_bfw_facade_generator=>directions-changing THEN class_builder-changing
                       WHEN zcl_bfw_facade_generator=>directions-returning THEN class_builder-returning
                       ELSE class_builder-importing ).
  ENDMETHOD.
ENDCLASS.
