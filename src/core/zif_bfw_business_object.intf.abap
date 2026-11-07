"! Access to the instances of one classic BOPF business object. Nodes, associations (including cross-BO associations
"! and dependent objects), alternative keys and queries are addressed by name and resolved at runtime from the BOPF
"! configuration. Nodes of a dependent object are qualified with their delegated node, e.g. STOPTEXTCOLLECTION.TEXT;
"! the delegated node alone addresses the root of the dependent object.
"! Business messages are returned; technical errors raise ZCX_BFW_ACCESS (unchecked).
INTERFACE zif_bfw_business_object
  PUBLIC.

  TYPES instance_key TYPE sysuuid_x16.

  TYPES:
    BEGIN OF key_entry,
      key TYPE instance_key,
    END OF key_entry,
    keys TYPE STANDARD TABLE OF key_entry WITH EMPTY KEY.

  TYPES:
    BEGIN OF key_link,
      source_key TYPE instance_key,
      target_key TYPE instance_key,
    END OF key_link,
    key_links TYPE STANDARD TABLE OF key_link WITH EMPTY KEY.

  TYPES:
    "! Position of an alternative-key value in the input table and the key of the instance it identifies
    BEGIN OF key_index,
      index TYPE i,
      key   TYPE instance_key,
    END OF key_index,
    key_indexes TYPE STANDARD TABLE OF key_index WITH EMPTY KEY.

  TYPES field_names TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  TYPES:
    BEGIN OF message,
      severity        TYPE bapiret2-type,
      business_object TYPE string,
      node            TYPE string,
      key             TYPE instance_key,
      fields          TYPE field_names,
      bapi_return     TYPE bapiret2,
    END OF message,
    messages TYPE STANDARD TABLE OF message WITH EMPTY KEY.

  TYPES:
    "! Selection of a query, like a range: SIGN I / E, OPTION EQ, BT, CP, ...
    BEGIN OF selection_parameter,
      attribute_name TYPE string,
      sign           TYPE c LENGTH 1,
      option         TYPE c LENGTH 2,
      low            TYPE string,
      high           TYPE string,
    END OF selection_parameter,
    selection_parameters TYPE STANDARD TABLE OF selection_parameter WITH EMPTY KEY.

  TYPES:
    "! Sort order of a query result: an attribute of the node, ascending unless DESCENDING is set
    BEGIN OF sort_entry,
      attribute_name TYPE string,
      descending     TYPE abap_bool,
    END OF sort_entry,
    sorting TYPE STANDARD TABLE OF sort_entry WITH EMPTY KEY.

  TYPES:
    "! One page of a query result, with MAXIMUM_ROWS of the query as the page size: START_ROW counts from 1;
    "! alternatively START_KEY, the last key of the previous page, for which BOPF's generic query returns the
    "! instances with a greater key
    BEGIN OF paging,
      start_row TYPE i,
      start_key TYPE instance_key,
    END OF paging.

  TYPES:
    "! Transactional contracts for the controlled SAP LUW, e.g. in RAP: reads may be called in every phase, changes
    "! only where RAP allows modifications. READ also for READ, which locks with FOR_UPDATE, because RAP read and lock
    "! handlers may call only READ. Weak, because BOPF itself can break a contract (locks, update tasks in actions):
    "! a violation is logged, not a runtime error.
    BEGIN OF tx_contract,
      read                    TYPE if_abap_tx_read=>ty_weak,
      read_reference          TYPE if_abap_tx_read=>ty_weak,
      read_by_association     TYPE if_abap_tx_read=>ty_weak,
      convert_alternative_key TYPE if_abap_tx_read=>ty_weak,
      query                   TYPE if_abap_tx_read=>ty_weak,
      create                  TYPE if_abap_tx_modify=>ty_weak,
      update                  TYPE if_abap_tx_modify=>ty_weak,
      delete                  TYPE if_abap_tx_modify=>ty_weak,
      execute_action          TYPE if_abap_tx_modify=>ty_weak,
    END OF tx_contract.

  "! Reads node instances by key. The components of the line type of ROWS are filled by name from the node; each of
  "! them must exist in the node structure.
  "! @parameter for_update       | Locks the instances exclusively; instances that cannot be locked are still
  "!                               returned, their keys are added to FAILED_KEYS
  "! @parameter before_image     | Reads the database state, without the changes of the transaction not saved yet
  "! @parameter invalidate_cache | Reloads the instances of persistent nodes from the database instead of the buffer
  "! @parameter failed_keys      | Keys of instances that do not exist or (FOR_UPDATE) could not be locked
  METHODS read
    IMPORTING
      node             TYPE string
      keys             TYPE keys
      for_update       TYPE abap_bool DEFAULT abap_false
      before_image     TYPE abap_bool DEFAULT abap_false
      invalidate_cache TYPE abap_bool DEFAULT abap_false
    EXPORTING
      rows             TYPE INDEX TABLE
      failed_keys      TYPE keys
      messages         TYPE messages.

  "! Reads node instances by key into a table of the node's own table type, for a cast at the call site
  METHODS read_reference
    IMPORTING
      node          TYPE string
      keys          TYPE keys
    RETURNING
      VALUE(result) TYPE REF TO data.

  "! Follows an association from the instances of KEYS. ROWS (optional) are the target instances, filled by name
  "! like in READ.
  "! @parameter filter              | Values for an association with parameters, e.g. a language: a structure mapped
  "!                                  by name to the parameter structure of the association; ignored for an
  "!                                  association without parameters
  "! @parameter filtered_attributes | Components of FILTER that filter; default: those that are not initial. Needed
  "!                                  only to filter for an initial value.
  "! @parameter before_image        | See READ
  "! @parameter invalidate_cache    | See READ
  "! @parameter failed_keys         | Source keys of instances that do not exist
  METHODS read_by_association
    IMPORTING
      node                TYPE string
      association         TYPE string
      keys                TYPE keys
      filter              TYPE any OPTIONAL
      filtered_attributes TYPE field_names OPTIONAL
      before_image        TYPE abap_bool DEFAULT abap_false
      invalidate_cache    TYPE abap_bool DEFAULT abap_false
    EXPORTING
      links               TYPE key_links
      rows                TYPE INDEX TABLE
      failed_keys         TYPE keys
      messages            TYPE messages.

  "! Finds the instances for values of an alternative key. ROWS (optional) are filled by name like in READ.
  "! @parameter values           | Values with the line type of the alternative key
  "! @parameter before_image     | See READ
  "! @parameter invalidate_cache | See READ
  "! @parameter key_indexes      | Index of each found value in VALUES with its key; values not found are missing
  METHODS convert_alternative_key
    IMPORTING
      node             TYPE string
      alternative_key  TYPE string
      values           TYPE INDEX TABLE
      before_image     TYPE abap_bool DEFAULT abap_false
      invalidate_cache TYPE abap_bool DEFAULT abap_false
    EXPORTING
      keys             TYPE keys
      key_indexes      TYPE key_indexes
      rows             TYPE INDEX TABLE
      messages         TYPE messages.

  "! Runs a query of a node. ROWS (optional) are filled by name like in READ; a standard table keeps the order of
  "! KEYS, a sorted table (e.g. a node table type sorted by KEY) its own order. BOPF's generic queries apply SORTING
  "! and PAGING; a query class of a business object applies only what it implements.
  "! @parameter filter_keys  | Restricts the result to these instances; empty = no restriction
  "! @parameter maximum_rows | 0 = no limit; with PAGING the page size
  "! @parameter sorting      | Sort order of KEYS and ROWS
  METHODS query
    IMPORTING
      node                 TYPE string
      query                TYPE string
      selection_parameters TYPE selection_parameters OPTIONAL
      filter_keys          TYPE keys OPTIONAL
      maximum_rows         TYPE i DEFAULT 0
      sorting              TYPE sorting OPTIONAL
      paging               TYPE paging OPTIONAL
    EXPORTING
      keys                 TYPE keys
      rows                 TYPE INDEX TABLE
      messages             TYPE messages.

  "! Creates node instances in the transactional buffer. Instances of a subnode need the component PARENT_KEY in
  "! ROWS; the composition from the parent is taken from the configuration.
  "! @parameter rows        | Components are mapped by name; an initial KEY gets a new key, which is written back
  "! @parameter failed_keys | Keys of rows that BOPF did not create, e.g. because the parent is locked; a row with a
  "!                          consistency error is created and has only a message
  METHODS create
    IMPORTING
      node        TYPE string
    EXPORTING
      failed_keys TYPE keys
      messages    TYPE messages
    CHANGING
      rows        TYPE INDEX TABLE.

  "! Changes node instances in the transactional buffer. Only fields whose value differs from the current state are
  "! sent to BOPF; instances without a difference are not changed.
  "! @parameter rows           | Need the component KEY; the other components are mapped by name
  "! @parameter changed_fields | Sends exactly these fields instead of comparing with the current state
  "! @parameter failed_keys    | Keys of instances that do not exist or are locked; BOPF keeps a change with a
  "!                             consistency error and only reports the error
  METHODS update
    IMPORTING
      node           TYPE string
      rows           TYPE INDEX TABLE
      changed_fields TYPE field_names OPTIONAL
    EXPORTING
      failed_keys    TYPE keys
      messages       TYPE messages.

  "! Deletes node instances including their subnodes in the transactional buffer
  "! @parameter failed_keys | Keys of instances that do not exist, are locked or still exist after the deletion
  METHODS delete
    IMPORTING
      node        TYPE string
      keys        TYPE keys
    EXPORTING
      failed_keys TYPE keys
      messages    TYPE messages.

  "! Executes an action of a node
  "! @parameter keys        | Instances to execute the action on; empty for static actions
  "! @parameter parameters  | Structure mapped by name to the parameter structure of the action
  "! @parameter rows        | Result of the action, mapped by name like in READ
  "! @parameter failed_keys | Keys for which the action failed or could not be executed
  METHODS execute_action
    IMPORTING
      node        TYPE string
      action      TYPE string
      keys        TYPE keys OPTIONAL
      parameters  TYPE any OPTIONAL
    EXPORTING
      rows        TYPE INDEX TABLE
      failed_keys TYPE keys
      messages    TYPE messages.

ENDINTERFACE.
