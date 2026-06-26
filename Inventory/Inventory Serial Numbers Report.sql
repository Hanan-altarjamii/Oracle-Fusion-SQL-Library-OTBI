/*
===============================================================================
Oracle Fusion SCM - Inventory Serial Numbers Report
Author: Hanan Altarjami

Purpose:
    This query retrieves serial number details for inventory items,
    including item information, organization details, and serial status.

Business Use:
    - Tracking serialized inventory items
    - Inventory traceability and control
    - Operational reporting in Oracle Fusion SCM

Tables Used:
    - INV_SERIAL_NUMBERS      (Serial number transactions)
    - EGP_SYSTEM_ITEMS        (Item master data)
    - INV_ORG_PARAMETERS      (Inventory organization details)

Filters:
    - Item Number (optional parameter)
    - Organization Code (optional parameter)
    - Only active/valid serial status = 3

Module:
    Oracle Fusion SCM – Inventory Management
===============================================================================
*/

SELECT DISTINCT
    item.ITEM_NUMBER,                          -- Inventory Item Number
    serl.SERIAL_NUMBER,                       -- Serial Number
    serl.CURRENT_STATUS,                      -- Current Serial Status
    orgp.ORGANIZATION_CODE,                   -- Organization Code
    serl.CURRENT_SUBINVENTORY_CODE,          -- Subinventory Location
    item.DESCRIPTION                         -- Item Description

FROM INV_SERIAL_NUMBERS serl

-- Join with Item Master to get item details
INNER JOIN EGP_SYSTEM_ITEMS item
    ON item.INVENTORY_ITEM_ID = serl.INVENTORY_ITEM_ID

-- Join with Organization Parameters
INNER JOIN INV_ORG_PARAMETERS orgp
    ON orgp.ORGANIZATION_ID = serl.CURRENT_ORGANIZATION_ID

WHERE 1 = 1

-- Filter: Only specific serial status (e.g., Active/Issued depending on setup)
AND serl.CURRENT_STATUS = 3

-- Optional filter: Item Number
AND item.ITEM_NUMBER = NVL(:Item_number, item.ITEM_NUMBER)

-- Optional filter: Organization Code
AND orgp.ORGANIZATION_CODE = NVL(:ORGANIZATION_CODE, orgp.ORGANIZATION_CODE);