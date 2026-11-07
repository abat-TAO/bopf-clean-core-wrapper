@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'BOPF wrapper demo: sales order as RAP BO'
define root view entity ZBFW_R_DemoOrder
  as select from    /bobf/dm_sord_rt as SalesOrder
    left outer join /bobf/dm_cst_hdr as Customer on Customer.db_key = SalesOrder.customer_id_int
{
  key SalesOrder.db_key          as OrderKey,
      SalesOrder.order_id        as OrderId,
      Customer.customer_id       as CustomerId,
      SalesOrder.sales_org       as SalesOrganization,
      @Semantics.amount.currencyCode: 'Currency'
      SalesOrder.amount          as Amount,
      SalesOrder.amount_curr     as Currency,
      SalesOrder.delivery_status as DeliveryStatus
}
