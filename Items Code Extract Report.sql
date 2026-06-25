
/*

===============================================================================
Report Name: Items Code Extract Report

Author: Hanan Altarjami

Purpose: Extract item master data including UOM, category, costing, purchasing, and inventory attributes

Tables Used: INV_ORGANIZATION_DEFINITIONS_V, EGP_SYSTEM_ITEMS, EGP_ITEM_RELATIONSHIPS_B, 
INV_UNITS_OF_MEASURE_B, INV_UNITS_OF_MEASURE_TL, EGP_ITEM_CATEGORIES, EGP_CATEGORIES_VL, FND_LOOKUP_VALUES, FA_CATEGORIES_B

Report Output: Item master extract with organization, classification, and control attributes

Parameters: :Item_number, :OEM_Number


Module: Oracle Fusion SCM – Product Management
===============================================================================
*/

SELECT  
     esi.item_number,  -- Item Number (Code of the item)

     esi.description,  -- Item Description

     (
         SELECT
             c.unit_of_measure  -- Unit of Measure Description
         FROM
             inv_units_of_measure_tl c,
             inv_units_of_measure_b a
         WHERE
             a.unit_of_measure_id = c.unit_of_measure_id
             AND a.uom_code = esi.primary_uom_code
             AND c.language = 'US'
     ) primary_uom_code,  -- Primary UOM Code

     iod.organization_name,  -- Organization Name

     (
         SELECT
             ec.category_name  -- Item Category Name
         FROM
             egp_item_categories eic,
             egp_categories_vl ec
         WHERE
             eic.category_id = ec.category_id
             AND eic.inventory_item_id = esi.inventory_item_id
             AND eic.organization_id = esi.organization_id
             AND ROWNUM = 1
     ) category,  -- Primary Category (first matched)

     esi.inventory_item_status_code   item_status,  -- Item Status Code

     (
         SELECT
             a.meaning  -- Item Type Meaning
         FROM
             fnd_lookup_values a
         WHERE
             upper(a.lookup_type) = 'EGP_ITEM_TYPE'
             AND a.lookup_code = esi.item_type
             AND a.language = 'US'
     ) item_type,  -- Item Type Description

     CASE
         WHEN esi.costing_enabled_flag = 'Y' THEN 'Yes'
         WHEN esi.costing_enabled_flag = 'N' THEN 'No'
         ELSE NULL
     END cst_ena,  -- Costing Enabled Flag

     CASE
         WHEN esi.inventory_asset_flag = 'Y' THEN 'Yes'
         WHEN esi.inventory_asset_flag = 'N' THEN 'No'
         ELSE NULL
     END inv_asst,  -- Inventory Asset Flag

     (
         SELECT
             a.meaning  -- Asset Tracking Meaning
         FROM
             fnd_lookup_values a
         WHERE
             upper(a.lookup_type) = 'ORA_EGP_ASSET_TRACKING'
             AND a.lookup_code = esi.asset_tracked_flag
             AND a.language = 'US'
     ) asst_trc1,  -- Asset Tracking Status

     CASE
         WHEN esi.allow_maintenance_asset_flag = 'Y' THEN 'Yes'
         WHEN esi.allow_maintenance_asset_flag = 'N' THEN 'No'
         ELSE NULL
     END asst_mait,  -- Maintenance Asset Flag

     CASE
         WHEN esi.inventory_item_flag = 'Y' THEN 'Yes'
         WHEN esi.inventory_item_flag = 'N' THEN 'No'
         ELSE NULL
     END inv_itm,  -- Inventory Item Flag

     CASE
         WHEN esi.stock_enabled_flag = 'Y' THEN 'Yes'
         WHEN esi.stock_enabled_flag = 'N' THEN 'No'
         ELSE NULL
     END stk,  -- Stock Enabled Flag

     CASE
         WHEN esi.mtl_transactions_enabled_flag = 'Y' THEN 'Yes'
         WHEN esi.mtl_transactions_enabled_flag = 'N' THEN 'No'
         ELSE NULL
     END txn_ena,  -- Material Transactions Enabled Flag

     CASE
         WHEN esi.reservable_type = 1 THEN 'Yes'
         WHEN esi.reservable_type = 2 THEN 'No'
         ELSE NULL
     END rsr,  -- Reservable Flag

     (
         SELECT
             a.meaning  -- Lot Control Meaning
         FROM
             fnd_lookup_values a
         WHERE
             upper(a.lookup_type) = 'INV_LOT_CONTROL'
             AND a.lookup_code = TO_CHAR(esi.lot_control_code)
             AND a.language = 'US'
     ) lot_ctrl,  -- Lot Control Type

     (
         SELECT
             a.meaning  -- Shelf Life Meaning
         FROM
             fnd_lookup_values a
         WHERE
             upper(a.lookup_type) = 'ORA_MSC_LOT_EXPIRATION_CONTROL'
             AND a.lookup_code = TO_CHAR(esi.shelf_life_code)
             AND a.language = 'US'
     ) lot_exp_ctrl,  -- Lot Expiration Control

     (
         SELECT
             a.meaning  -- Serial Control Meaning
         FROM
             fnd_lookup_values a
         WHERE
             upper(a.lookup_type) = 'INV_SERIAL_NUMBER'
             AND a.lookup_code = TO_CHAR(esi.serial_number_control_code)
             AND a.language = 'US'
     ) ser_gen,  -- Serial Number Control

     CASE
         WHEN esi.purchasing_item_flag = 'Y' THEN 'Yes'
         WHEN esi.purchasing_item_flag = 'N' THEN 'No'
         ELSE NULL
     END purchased,  -- Purchasing Item Flag

     CASE
         WHEN esi.purchasing_enabled_flag = 'Y' THEN 'Yes'
         WHEN esi.purchasing_enabled_flag = 'N' THEN 'No'
         ELSE NULL
     END purchasable,  -- Purchasable Flag

     CASE
         WHEN esi.allow_item_desc_update_flag = 'Y' THEN 'Yes'
         WHEN esi.allow_item_desc_update_flag = 'N' THEN 'No'
         ELSE NULL
     END allow_desc,  -- Allow Description Update

     (
         SELECT
             b.segment1 || ' ' || b.segment2 || ' ' || b.segment3  -- Asset Category Code
         FROM
             fa_categories_b b
         WHERE
             b.category_id = esi.asset_category_id
     ) asst_cat,  -- Asset Category

     esi.list_price_per_unit          list_price,  -- List Price Per Unit

     CASE
         WHEN esi.outside_process_service_flag = 'Y' THEN 'Yes'
         WHEN esi.outside_process_service_flag = 'N' THEN 'No'
         ELSE NULL
     END out_prc,  -- Outside Processing Flag

     esi.match_approval_level         appr_lvl,  -- Match Approval Level

     esi.invoice_match_option         inv_mtc,  -- Invoice Match Option

     (
         SELECT
             meaning  -- Receiving Routing Meaning
         FROM
             fnd_lookup_values
         WHERE
             upper(lookup_type) LIKE 'EGP_RECEIPTROUTVS_TYPE'
             AND lookup_code = TO_CHAR(esi.receiving_routing_id)
             AND language = 'US'
     ) rct_rut,  -- Receiving Routing

     d1.cross_reference,  -- Cross Reference (OEM)

     d1.cross_reference               crs_ref,  -- OEM Cross Reference Alias

     esi.MIN_MINMAX_QUANTITY,  -- Minimum Quantity

     esi.MAX_MINMAX_QUANTITY   -- Maximum Quantity

FROM
     inv_organization_definitions_v iod,  -- Organization Table
     egp_system_items esi,  -- System Items Table
     egp_item_relationships_b d1  -- Item Relationships Table

WHERE
     iod.organization_id = esi.organization_id
     AND d1.inventory_item_id (+)= esi.inventory_item_id
     AND d1.organization_id (+)= esi.organization_id
     AND sub_type (+)= 'OEM_NUMBER'
     and iod.organization_id=300000003715096
     AND esi.item_number = NVL(:Item_number, esi.item_number)
     AND (:OEM_Number IS NULL OR d1.cross_reference = :OEM_Number)

ORDER BY
     iod.organization_name,  -- Sort by Organization
     esi.item_number     -- Sort by Item Number