/* 
===============================================================================
ITEM MASTER REPORT (Oracle Fusion SCM)
Author: Hanan Altarjami

Purpose:
    Retrieve item master details including item number, OEM reference,
    description, UOM, category, and item type.

Module:
Oracle Fusion Cloud SCM – Product Management (PIM)
===============================================================================
*/

SELECT DISTINCT  
    esi.item_number,  -- Item number (internal identifier)

    b.CROSS_REFERENCE AS OEM_NUMBER,  -- OEM cross reference number

    esi.description,  -- Item description

    /* Primary UOM (Unit of Measure) */
    (
        SELECT
            c.unit_of_measure
        FROM
            inv_units_of_measure_tl c,
            inv_units_of_measure_b a
        WHERE
            a.unit_of_measure_id = c.unit_of_measure_id
            AND a.uom_code = esi.primary_uom_code
            AND c.language = 'US'
    ) primary_uom_code,

    /* Item Category (first available category) */
    (
        SELECT
            ec.category_name
        FROM
            egp_item_categories eic,
            egp_categories_vl ec
        WHERE
            eic.category_id = ec.category_id
            AND eic.inventory_item_id = esi.inventory_item_id
            AND eic.organization_id = esi.organization_id
            AND ROWNUM = 1
    ) category,

    /* Item Type (lookup meaning) */
    (
        SELECT
            a.meaning
        FROM
            fnd_lookup_values a
        WHERE
            UPPER(a.lookup_type) = 'EGP_ITEM_TYPE'
            AND a.lookup_code = esi.item_type
            AND a.language = 'US'
    ) item_type


FROM 
    egp_system_items esi,
    egp_item_relationships_b b

WHERE 
    esi.inventory_item_id = b.inventory_item_id(+)
    AND b.sub_type(+) = 'OEM_NUMBER'
    AND esi.inventory_item_status_code = 'Active'
    AND esi.item_number = NVL(:Item_number, esi.item_number)
    AND b.CROSS_REFERENCE = NVL(:OEM_NUMBER, b.CROSS_REFERENCE)