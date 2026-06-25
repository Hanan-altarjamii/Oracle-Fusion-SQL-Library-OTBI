/*
===============================================================================
Report Name: Item Stock with Cost Report
Author: Hanan Altarjami

Purpose:
    This report retrieves item stock details along with costing information,
    including unit cost, currency, valuation unit, on-hand quantity, subinventory,
    locator details, and organization information. It combines costing data with
    inventory on-hand balances to provide a complete stock valuation view.

Tables Used:
    cst_cost_inv_orgs
    cst_item_cost_profiles
    cst_cost_profiles_b
    cst_val_units_b
    cst_val_structures_b
    cst_val_unit_details
    cst_val_unit_combinations
    cst_perpavg_cost
    cst_cost_orgs_v
    inv_org_parameters
    cst_transactions
    inv_onhand_quantities_detail
    egp_system_items_vl
    inv_item_locations

Report Output:
    Item Number, Description, Unit Cost Average, Currency, UOM,
    On-hand Quantity, Subinventory, Locator, Organization Code,
    Cost Organization Name, Valuation Unit Details

Parameters:
    :p_item_number
    :p_subinventory_code
    :p_organization_code

Notes:
    Filters only items with on-hand quantity > 0 and allows optional filtering
    by item number, subinventory, and organization code.

Module:
    Oracle Fusion SCM - Product Management

===============================================================================
*/

WITH costing_details AS (
    SELECT *
    FROM (
        SELECT
            TRUNC(cpc.unit_cost_average, 4)   AS unit_cost_average,
            cpc.uom_code                      AS uom,
            cpc.currency_code                 AS curr,
            vub.val_unit_id,
            vub.val_unit_code,
            cicp.inventory_item_id            AS item_id,
            ccio.inv_org_id,
            RANK() OVER (
                PARTITION BY
                    cicp.cost_org_id,
                    cicp.cost_book_id,
                    cpc.inventory_item_id,
                    cpc.val_unit_id
                ORDER BY
                    cpc.cost_date DESC,
                    cpc.eff_date  DESC,
                    cpc.transaction_id DESC
            ) AS row_num,
            iop.organization_code AS org_name,
            cco.cost_org_name
        FROM
            cst_cost_inv_orgs ccio,
            cst_item_cost_profiles cicp,
            cst_cost_profiles_b ccp,
            cst_val_units_b vub,
            cst_val_structures_b vsb,
            cst_val_unit_details vud,
            cst_val_unit_combinations vuc,
            cst_perpavg_cost cpc,
            cst_cost_orgs_v cco,
            inv_org_parameters iop,
            cst_transactions ct
        WHERE
            ct.cost_org_id = cpc.cost_org_id
            AND ct.cost_book_id = cpc.cost_book_id
            AND ct.val_unit_id = cpc.val_unit_id
            AND ct.transaction_id = cpc.transaction_id
            AND ccio.cost_org_id = cicp.cost_org_id
            AND ccp.cost_profile_id = cicp.asset_cost_profile_id
            AND vub.cost_org_id = cicp.cost_org_id
            AND vub.cost_book_id = cicp.cost_book_id
            AND vub.val_structure_id = ccp.val_structure_id
            AND vub.val_unit_id = vud.val_unit_id
            AND vud.val_unit_combination_id = vuc.val_unit_combination_id
            AND ccp.val_structure_id = vsb.val_structure_id
            AND vsb.structure_instance_number = vuc.structure_instance_number
            AND vub.cost_org_id = cco.cost_org_id
            AND iop.organization_id = ccio.inv_org_id
            AND vuc.cost_org_code = cco.cost_org_code
            AND NVL(vuc.inv_org_code, iop.organization_code) = iop.organization_code
            AND cpc.cost_org_id = cicp.cost_org_id
            AND cpc.cost_book_id = cicp.cost_book_id
            AND cpc.inventory_item_id = cicp.inventory_item_id
            AND cpc.val_unit_id = vub.val_unit_id
            AND TRUNC(cpc.cost_date) <= TRUNC(ct.cost_date)
            AND cpc.cost_book_id = (
                SELECT ccb.cost_book_id
                FROM cst_cost_org_books ccb
                WHERE ccb.cost_org_id = cicp.cost_org_id
                  AND ccb.primary_book_flag = 'Y'
            )
            AND vsb.val_structure_type_code IN ('ASSET', 'EXPENSE')
    )
    WHERE row_num = 1
),
oh AS (
    SELECT
        inventory_item_id,
        organization_id,
        subinventory_code,
        locator_id,
        CAST(
            SUM(PRIMARY_TRANSACTION_QUANTITY)
            AS NUMBER(18,4)
        ) AS onhand_qty

        
    FROM inv_onhand_quantities_detail
    GROUP BY
        inventory_item_id,
        organization_id,
        subinventory_code,
        locator_id
)

SELECT
    CASE
        WHEN oh.subinventory_code = 'STyreStore'
         AND iop.organization_code = 'JEDWORKSHOP'
        THEN 0
        ELSE cd.unit_cost_average
    END AS unit_cost_average,

    cd.uom,
    cd.curr,
    cd.val_unit_id,
    cd.val_unit_code,
    cd.item_id,
    cd.inv_org_id,
    cd.org_name,
    cd.cost_org_name,

    esi.item_number,
    NVL(oh.onhand_qty, 0)          AS on_hand,
    oh.subinventory_code,
    iop.organization_code,
    esi.description,

    /* 🔹 Locator details */
    loc.LOCATOR_NAME
FROM costing_details cd

JOIN egp_system_items_vl esi
    ON esi.inventory_item_id = cd.item_id
   AND esi.organization_id   = cd.inv_org_id
JOIN inv_org_parameters iop
    ON iop.organization_id   = esi.organization_id
LEFT JOIN oh
    ON oh.inventory_item_id = esi.inventory_item_id
   AND oh.organization_id   = esi.organization_id
LEFT JOIN inv_item_locations loc
    ON loc.inventory_location_id = oh.locator_id
   AND loc.organization_id       = oh.organization_id

WHERE
    esi.item_number = NVL(:p_item_number, esi.item_number)
    AND NVL(oh.onhand_qty, 0) > 0

   /* 🔹 Subinventory filter (optional) */
    AND oh.subinventory_code =
        NVL(:p_subinventory_code, oh.subinventory_code)

    /* 🔹 Organization Code filter (optional) */
    AND iop.organization_code =
        NVL(:p_organization_code, iop.organization_code)

ORDER BY
    esi.item_number,
    cd.org_name,
    oh.subinventory_code,
    loc.LOCATOR_NAME;