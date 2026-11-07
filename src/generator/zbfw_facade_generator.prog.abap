"! Generates a typed facade class for a classic BOPF business object: one method per selected node, association,
"! alternative key, action or query, each delegating to the BOPF wrapper engine. Enter the name of an existing
"! facade and press Enter to load its selection, business object and package. F4 on a selection lists the names
"! of the business object; the chosen ones are added. Never edit a generated class by hand; change the selection
"! here and generate again.
REPORT zbfw_facade_generator.

DATA selection_name TYPE c LENGTH 70.

SELECTION-SCREEN BEGIN OF BLOCK target WITH FRAME TITLE TEXT-001.
PARAMETERS p_facade TYPE seoclsname OBLIGATORY.
PARAMETERS p_bo TYPE /bobf/conf_bo_name.
PARAMETERS p_devc TYPE devclass.
PARAMETERS p_trkorr TYPE trkorr.
SELECTION-SCREEN END OF BLOCK target.

SELECTION-SCREEN BEGIN OF BLOCK entries WITH FRAME TITLE TEXT-002.
SELECT-OPTIONS s_nodes FOR selection_name NO INTERVALS.
SELECT-OPTIONS s_writes FOR selection_name NO INTERVALS.
SELECT-OPTIONS s_assocs FOR selection_name NO INTERVALS.
SELECT-OPTIONS s_altkey FOR selection_name NO INTERVALS.
SELECT-OPTIONS s_action FOR selection_name NO INTERVALS.
SELECT-OPTIONS s_query FOR selection_name NO INTERVALS.
SELECTION-SCREEN END OF BLOCK entries.


CLASS lcl_facade_report DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES selection_options LIKE RANGE OF selection_name.

    "! Fills the screen from an existing facade, but only while nothing else has been entered
    METHODS load_selection.

    METHODS generate.

    "! Lists the names of one kind for the business object on the screen and adds the chosen ones
    "! @parameter kind    | One of ZCL_BFW_METADATA=>SELECTABLE_KINDS
    "! @parameter options | Select-option the chosen names are added to, without duplicates
    METHODS show_value_help
      IMPORTING
        kind    TYPE string
      CHANGING
        options TYPE selection_options.

  PRIVATE SECTION.
    "! The business object on the screen; an input help does not transport screen values to the program
    METHODS read_business_object
      RETURNING
        VALUE(result) TYPE string.

    METHODS get_selectable_names
      IMPORTING
        business_object TYPE string
        kind            TYPE string
      RETURNING
        VALUE(result)   TYPE zcl_bfw_metadata=>selectable_names.

    METHODS is_screen_empty
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS get_selection
      RETURNING
        VALUE(result) TYPE string_table.

    METHODS to_selection_lines
      IMPORTING
        kind          TYPE string
        options       TYPE selection_options
      RETURNING
        VALUE(result) TYPE string_table.

    METHODS write_lines
      IMPORTING
        lines TYPE string_table.
ENDCLASS.


CLASS lcl_facade_report IMPLEMENTATION.

  METHOD load_selection.
    DATA option TYPE LINE OF selection_options.

    IF is_screen_empty( ) = abap_false.
      RETURN.
    ENDIF.
    DATA(writer) = NEW zcl_bfw_facade_writer( ).
    DATA(generator) = NEW zcl_bfw_facade_generator( ).
    DATA(selection_source) = writer->read_method_source( class_name  = p_facade
                                                         method_name = `GET_SELECTION` ).
    IF generator->is_generated_source( selection_source ) = abap_false.
      RETURN.
    ENDIF.

    generator->parse_selection( EXPORTING selection = generator->get_selection_from_source( selection_source )
                                IMPORTING entries   = DATA(entries) ).
    " The constructor holds the name of the business object as its only literal
    DATA(constructor_literals) = generator->get_selection_from_source(
                                   writer->read_method_source( class_name  = p_facade
                                                               method_name = `CONSTRUCTOR` ) ).
    p_bo = VALUE #( constructor_literals[ 1 ] OPTIONAL ).
    SELECT SINGLE devclass FROM tadir
      WHERE pgmid    = 'R3TR'
        AND object   = 'CLAS'
        AND obj_name = @p_facade
      INTO @p_devc.
    IF sy-subrc <> 0.
      CLEAR p_devc.
    ENDIF.

    LOOP AT entries ASSIGNING FIELD-SYMBOL(<entry>).
      option = VALUE #( sign   = 'I'
                        option = 'EQ'
                        low    = COND string( WHEN <entry>-alias IS INITIAL
                                              THEN <entry>-name
                                              ELSE |{ <entry>-name } = { <entry>-alias }| ) ).
      CASE <entry>-kind.
        WHEN zcl_bfw_facade_generator=>kinds-node.
          INSERT option INTO TABLE s_nodes.
        WHEN zcl_bfw_facade_generator=>kinds-writable_node.
          INSERT option INTO TABLE s_writes.
        WHEN zcl_bfw_facade_generator=>kinds-association.
          INSERT option INTO TABLE s_assocs.
        WHEN zcl_bfw_facade_generator=>kinds-alternative_key.
          INSERT option INTO TABLE s_altkey.
        WHEN zcl_bfw_facade_generator=>kinds-action.
          INSERT option INTO TABLE s_action.
        WHEN zcl_bfw_facade_generator=>kinds-query.
          INSERT option INTO TABLE s_query.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD generate.
    DATA(generator) = NEW zcl_bfw_facade_generator( ).
    generator->build( EXPORTING business_object = p_bo
                                class_name      = p_facade
                                selection       = get_selection( )
                      IMPORTING facade          = DATA(facade)
                                errors          = DATA(errors) ).
    IF errors IS INITIAL.
      errors = NEW zcl_bfw_facade_writer( )->write( facade    = facade
                                                    package   = p_devc
                                                    transport = p_trkorr ).
    ENDIF.

    IF errors IS NOT INITIAL.
      write_lines( VALUE #( ( |{ p_facade }: not generated or not activated| )
                            ( LINES OF errors ) ) ).
      RETURN.
    ENDIF.
    write_lines( VALUE #( ( |{ facade-class_name } was generated and activated with these methods:| )
                          ( LINES OF VALUE string_table( FOR method IN facade-methods ( method-name ) ) ) ) ).
  ENDMETHOD.


  METHOD show_value_help.
    CONSTANTS name_length TYPE i VALUE 70.
    CONSTANTS info_length TYPE i VALUE 100.
    TYPES:
      BEGIN OF value,
        name TYPE c LENGTH name_length,
        info TYPE c LENGTH info_length,
      END OF value.
    TYPES columns TYPE STANDARD TABLE OF dfies WITH EMPTY KEY.
    DATA values TYPE STANDARD TABLE OF value WITH EMPTY KEY.
    DATA chosen_values TYPE STANDARD TABLE OF ddshretval WITH EMPTY KEY.

    DATA(business_object) = read_business_object( ).
    TRY.
        DATA(names) = get_selectable_names( business_object = business_object
                                            kind            = kind ).
      CATCH zcx_bfw_access INTO DATA(error).
        MESSAGE ID error->if_t100_message~t100key-msgid TYPE 'S' NUMBER error->if_t100_message~t100key-msgno
                WITH error->if_t100_dyn_msg~msgv1 error->if_t100_dyn_msg~msgv2
                     error->if_t100_dyn_msg~msgv3 error->if_t100_dyn_msg~msgv4
                DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.

    values = VALUE #( FOR name IN names ( name = name-name
                                          info = name-info ) ).
    " Columns without dictionary types must be described: lengths in characters, offsets and internal lengths in bytes
    DATA(column_descriptions) = VALUE columns(
      ( fieldname = 'NAME'
        position  = 1
        offset    = 0
        inttype   = 'C'
        datatype  = 'CHAR'
        leng      = name_length
        outputlen = name_length
        intlen    = name_length * cl_abap_char_utilities=>charsize
        reptext   = 'Name'
        scrtext_s = 'Name'
        scrtext_m = 'Name'
        scrtext_l = 'Name' )
      ( fieldname = 'INFO'
        position  = 2
        offset    = name_length * cl_abap_char_utilities=>charsize
        inttype   = 'C'
        datatype  = 'CHAR'
        leng      = info_length
        outputlen = info_length
        intlen    = info_length * cl_abap_char_utilities=>charsize
        reptext   = 'Info'
        scrtext_s = 'Info'
        scrtext_m = 'Info'
        scrtext_l = 'Info' ) ).
    DATA(title) = CONV sytitle( |{ business_object }: { kind }| ).
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'NAME'
        value_org       = 'S'
        multiple_choice = abap_true
        window_title    = title
      TABLES
        value_tab       = values
        field_tab       = column_descriptions
        return_tab      = chosen_values
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    LOOP AT chosen_values ASSIGNING FIELD-SYMBOL(<chosen_value>).
      IF NOT line_exists( options[ low = <chosen_value>-fieldval ] ).
        INSERT VALUE #( sign   = 'I'
                        option = 'EQ'
                        low    = <chosen_value>-fieldval ) INTO TABLE options.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_business_object.
    DATA screen_values TYPE STANDARD TABLE OF rsselread WITH EMPTY KEY.

    screen_values = VALUE #( ( name = 'P_BO'
                               kind = 'P' ) ).
    CALL FUNCTION 'RS_SELECTIONSCREEN_READ'
      EXPORTING
        program     = sy-repid
      TABLES
        fieldvalues = screen_values.
    result = to_upper( condense( VALUE string( screen_values[ 1 ]-fieldvalue OPTIONAL ) ) ).
  ENDMETHOD.


  METHOD get_selectable_names.
    " The factory refuses business objects that are not classic BOPF
    zcl_bfw_factory=>get_business_object( business_object ).
    TRY.
        result = NEW zcl_bfw_metadata( /bobf/cl_frw_factory=>get_configuration(
                                         /bobf/cl_frw_factory=>query_bo( CONV #( business_object ) ) )
                                     )->get_selectable_names( kind ).
      CATCH /bobf/cx_frw INTO DATA(error).
        zcx_bfw_access=>raise_bopf_error( business_object = business_object
                                          previous        = error ).
    ENDTRY.
  ENDMETHOD.


  METHOD is_screen_empty.
    result = xsdbool( p_bo IS INITIAL
                  AND s_nodes[] IS INITIAL
                  AND s_writes[] IS INITIAL
                  AND s_assocs[] IS INITIAL
                  AND s_altkey[] IS INITIAL
                  AND s_action[] IS INITIAL
                  AND s_query[] IS INITIAL ).
  ENDMETHOD.


  METHOD get_selection.
    result = VALUE #( ( LINES OF to_selection_lines( kind    = zcl_bfw_facade_generator=>kinds-node
                                                     options = s_nodes[] ) )
                      ( LINES OF to_selection_lines( kind    = zcl_bfw_facade_generator=>kinds-writable_node
                                                     options = s_writes[] ) )
                      ( LINES OF to_selection_lines( kind    = zcl_bfw_facade_generator=>kinds-association
                                                     options = s_assocs[] ) )
                      ( LINES OF to_selection_lines( kind    = zcl_bfw_facade_generator=>kinds-alternative_key
                                                     options = s_altkey[] ) )
                      ( LINES OF to_selection_lines( kind    = zcl_bfw_facade_generator=>kinds-action
                                                     options = s_action[] ) )
                      ( LINES OF to_selection_lines( kind    = zcl_bfw_facade_generator=>kinds-query
                                                     options = s_query[] ) ) ).
  ENDMETHOD.


  METHOD to_selection_lines.
    result = VALUE #( FOR option IN options WHERE ( low IS NOT INITIAL )
                      ( |{ kind } { condense( option-low ) }| ) ).
  ENDMETHOD.


  METHOD write_lines.
    LOOP AT lines ASSIGNING FIELD-SYMBOL(<line>).
      WRITE / <line>.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


" The screen shows the header line of a select-option as its first line, and the next PAI writes the screen back to
" the first line. So whenever the program fills a select-option, its header line is set to the first line.
AT SELECTION-SCREEN ON p_facade.
  NEW lcl_facade_report( )->load_selection( ).
  s_nodes = VALUE #( s_nodes[ 1 ] OPTIONAL ).
  s_writes = VALUE #( s_writes[ 1 ] OPTIONAL ).
  s_assocs = VALUE #( s_assocs[ 1 ] OPTIONAL ).
  s_altkey = VALUE #( s_altkey[ 1 ] OPTIONAL ).
  s_action = VALUE #( s_action[ 1 ] OPTIONAL ).
  s_query = VALUE #( s_query[ 1 ] OPTIONAL ).


AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_nodes-low.
  NEW lcl_facade_report( )->show_value_help( EXPORTING kind    = zcl_bfw_metadata=>selectable_kinds-node
                                             CHANGING  options = s_nodes[] ).
  s_nodes = VALUE #( s_nodes[ 1 ] OPTIONAL ).


AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_writes-low.
  NEW lcl_facade_report( )->show_value_help( EXPORTING kind    = zcl_bfw_metadata=>selectable_kinds-node
                                             CHANGING  options = s_writes[] ).
  s_writes = VALUE #( s_writes[ 1 ] OPTIONAL ).


AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_assocs-low.
  NEW lcl_facade_report( )->show_value_help( EXPORTING kind    = zcl_bfw_metadata=>selectable_kinds-association
                                             CHANGING  options = s_assocs[] ).
  s_assocs = VALUE #( s_assocs[ 1 ] OPTIONAL ).


AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_altkey-low.
  NEW lcl_facade_report( )->show_value_help( EXPORTING kind    = zcl_bfw_metadata=>selectable_kinds-alternative_key
                                             CHANGING  options = s_altkey[] ).
  s_altkey = VALUE #( s_altkey[ 1 ] OPTIONAL ).


AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_action-low.
  NEW lcl_facade_report( )->show_value_help( EXPORTING kind    = zcl_bfw_metadata=>selectable_kinds-action
                                             CHANGING  options = s_action[] ).
  s_action = VALUE #( s_action[ 1 ] OPTIONAL ).


AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_query-low.
  NEW lcl_facade_report( )->show_value_help( EXPORTING kind    = zcl_bfw_metadata=>selectable_kinds-query
                                             CHANGING  options = s_query[] ).
  s_query = VALUE #( s_query[ 1 ] OPTIONAL ).


START-OF-SELECTION.
  NEW lcl_facade_report( )->generate( ).
