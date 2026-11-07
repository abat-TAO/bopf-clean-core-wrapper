# Development

## Repository layout

abapGit imports `src/` with the folder logic PREFIX: the root package (for example `ZBFW`) gets one subpackage per
folder.

| Folder           | Package          | Content                                                                         |
| ---------------- | ---------------- | ------------------------------------------------------------------------------- |
| `src/core/`      | `ZBFW_CORE`      | Engine `ZIF_BFW_BUSINESS_OBJECT` / `ZCL_BFW_BUSINESS_OBJECT`, factory `ZCL_BFW_FACTORY`, injector for test doubles `ZCL_BFW_INJECTOR`, metadata `ZCL_BFW_METADATA`, message converter `ZCL_BFW_MESSAGE_CONVERTER`, classic transaction `ZIF_BFW_TRANSACTION` / `ZCL_BFW_TRANSACTION`, RAP transaction `ZIF_BFW_RAP_TRANSACTION` / `ZCL_BFW_RAP_TRANSACTION`, RAP message `ZCL_BFW_RAP_MESSAGE`, exceptions `ZCX_BFW_ACCESS` and `ZCX_BFW_SAVE_REJECTED`, message class `ZBFW` |
| `src/generator/` | `ZBFW_GENERATOR` | Report `ZBFW_FACADE_GENERATOR`, model builder `ZCL_BFW_FACADE_GENERATOR`, class writer `ZCL_BFW_FACADE_WRITER` |
| `src/demo/`      | `ZBFW_DEMO`      | Demo facade `ZCL_BFW_DEMO_SO_FACADE`, test fixture `ZCL_BFW_TEST_FIXTURE` with the integration tests, RAP demo `ZBFW_R_DEMOORDER` (CDS view entity, behavior definition, behavior pool `ZBP_BFW_R_DEMOORDER`) and its run `ZCL_BFW_RAP_DEMO_RUN` |

The core needs nothing from the other packages; the generator and the demo use the core.

## Checks

abaplint checks the code against `abaplint.jsonc` (Clean ABAP: no prefixes, descriptive English names) with the
syntax of ABAP 7.58, the lowest tested release. The root `package.json` pins its version:

```bash
npm ci
npx abaplint abaplint.jsonc
```

SAP standard objects come from [abaplint/deps](https://github.com/abaplint/deps); clone it into `./deps` to work
offline. A clean abaplint run does not prove that the code compiles:

- abaplint treats SAP objects it does not know as void.
- The deps contain hardly any BOPF objects. Local test doubles that implement BOPF interfaces would give false
  errors, so `check_syntax` skips the test classes of `ZCL_BFW_BUSINESS_OBJECT`, `ZCL_BFW_TRANSACTION` and
  `ZCL_BFW_RAP_TRANSACTION`.
- abaplint does not report every SAP syntax error, e.g. a protected word such as `instance` as a type name,
  character literals as rows of a string table, or `TYPE RANGE OF` a data object.
- Newer releases accept statements that older ones reject, e.g. SAP_BASIS 816 accepts components outside the
  secondary key in `itab[ KEY key COMPONENTS ... ]`, 758 does not.

So after every import, run the syntax check of all objects in the SAP system, also on the lowest tested release,
and then ABAP Unit. An abapGit import
shows objects as active even with syntax errors, and a syntax error in a test include breaks the whole class at
runtime (dump `SYNTAX_ERROR`), not only its tests.

Rule exclusions in `abaplint.jsonc`: generated facades (`*_facade.clas.abap`) skip the layout rules
(`align_type_expressions`, `indentation`, `no_exclamation_escape`) because the class builder formats them; the engine
skips `no_dynamic_stuff` and `prefer_corresponding` (generic access by name); behavior pools skip `check_abstract`
and `unused_methods`.

Pull requests run abaplint with reviewdog (`.github/workflows/pr.yml`); only new findings fail the check. Dependabot
updates abaplint and the actions weekly; the reviewdog version in the workflow is updated by hand.

## Tests

ABAP Unit tests (risk level HARMLESS, duration SHORT) live in the test include of each class. Run them for the root
package including subpackages.

- **Unit tests** replace BOPF with local test doubles, e.g. of the service manager and the transaction manager.
  Callers of the wrapper can inject doubles of `ZIF_BFW_BUSINESS_OBJECT`, `ZIF_BFW_TRANSACTION` and
  `ZIF_BFW_RAP_TRANSACTION` into the factory with `ZCL_BFW_INJECTOR` (`FOR TESTING`); `reset( )` removes them.
- **Integration tests** (`LTCL_SALES_ORDER_INTEGRATION` in `ZCL_BFW_TEST_FIXTURE`) work on data of
  `/BOBF/DEMO_SALES_ORDER`. Run the class `ZCL_BFW_TEST_FIXTURE` once as a console application (F9): it creates and
  saves a customer, two products and two orders with items and texts, and skips what exists already. Without this
  data the integration tests are skipped ("Missing Prerequisites - run ZCL_BFW_TEST_FIXTURE first"). The tests
  leave the database unchanged.

## RAP demo

`ZBFW_R_DEMOORDER` is an unmanaged RAP business object (`strict(2)`, no draft) on the root of the demo sales order.
Its behavior pool `ZBP_BFW_R_DEMOORDER` implements the handlers with the engine (lock = read for update) and calls
`ZIF_BFW_RAP_TRANSACTION` in the saver.

`ZCL_BFW_RAP_DEMO_RUN` (console application, F9) runs EML `MODIFY ENTITIES` and `COMMIT ENTITIES`: create, update, a
create with an unknown customer, delete. It **writes to the database**: it first deletes leftovers of earlier runs
(order IDs `BFW-RAP-DEMO-%`) and at the end deletes both of its orders. It needs the customer of the fixture. The
create with the unknown customer is saved with BOPF's error message, because the demo sales order has no consistency
group; a save refused in `check_before_save` is covered by the unit tests of `ZCL_BFW_RAP_TRANSACTION`.

## Facades

How to use `ZBFW_FACADE_GENERATOR` (selection screen, entries and aliases, naming, regeneration, error messages) is
described in the [facade generator tutorial](facade-generator.md).

To update the demo facade, regenerate `ZCL_BFW_DEMO_SO_FACADE` in a system with the BOPF demo and take the class over
unchanged into `src/demo/`.

## Queries

- The engine passes `SORTING`, `MAXIMUM_ROWS` and `PAGING` to BOPF; it does not emulate paging.
- BOPF's generic queries such as `SELECT_ALL` and `SELECT_BY_ELEMENTS` sort and page: `START_ROW` counts from 1;
  alternatively `START_KEY` is the last key of the previous page.
- A query class of a business object applies only what it implements. TM's `ROOT_ELEMENTS` of `/SCMTMS/TOR` sorts
  and limits the rows, but ignores the start row.
- `ROWS` keep the order of `KEYS` when `ROWS` is a standard table; a sorted table keeps its own key order. TM's node
  table types (`_K`) are sorted by `KEY`, so a facade's query result is in key order. For the order of the query, call
  the engine with a standard table of the node's line type.

## Renaming

`tools/rename.mjs` renames the project code `BFW` and the namespace letter in `src/`, `docs/` and the README, and
checks SAP's name length limits; see the [README](../README.md#quick-start).

## Building a release

```bash
git archive --format=zip -o bopf-clean-core-wrapper-vX.Y.Z.zip vX.Y.Z .abapgit.xml src
```

The zip contains `.abapgit.xml` and `src/` and imports as an abapGit offline repository. Attach it to the GitHub
release of the tag.
