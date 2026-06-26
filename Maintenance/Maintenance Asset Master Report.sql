/*
===============================================================================
Maintenance Asset Master Report
Author: Hanan Altarjami

Purpose:
    Retrieve maintenance asset master information including asset details,
    fleet attributes, item information, organization details, and asset status.

Tables Used:
    - CSE_ASSETS_B
    - CSE_ASSETS_TL
    - EGP_SYSTEM_ITEMS_VL
    - INV_ORG_PARAMETERS

Report Output:
    Asset master and maintenance-related information.

Parameters:
    - None

Notes:
    - Asset attributes are stored in ATTRIBUTE columns.
    - Organization code is retrieved from INV_ORG_PARAMETERS.

Module:
    Oracle Fusion Supply Chain Execution  – Maintenance Management
===============================================================================
*/


SELECT DISTINCT

       -- Asset Number
       CFA.ASSET_NUMBER,

       -- Asset Identifier
       CFA.ASSET_ID,

       -- Serial Number
       CFA.SERIAL_NUMBER,

       -- Asset Quantity
       CFA.QUANTITY,

       -- Maintainable Flag
       CFA.MAINTAINABLE_FLAG,

       -- New Work Order Allowed Flag
       CFA.NEW_WO_ALLOWED_FLAG,

       -- Asset Description
       FAT.DESCRIPTION,

       -- Registration Number
       CFA.ATTRIBUTE_CHAR5 AS REGISTRATION_NUMBER,

       -- Make
       CFA.ATTRIBUTE_CHAR1 AS MAKE,

       -- Model
       CFA.ATTRIBUTE_CHAR2 AS MODEL,

       -- Year
       CFA.ATTRIBUTE_NUMBER1 AS YEAR_,

       -- Chassis Number
       CFA.ATTRIBUTE_CHAR3 AS CHASSIS_NUMBER,

       -- Engine Model Number
       CFA.ATTRIBUTE_CHAR6 AS ENGINE_MODEL_NUMBER,

       -- Engine Serial Number
       CFA.ATTRIBUTE_CHAR7 AS ENGINE_SERIAL_NUMBER,

       -- Engine Capacity
       CFA.ATTRIBUTE_CHAR8 AS ENGINE_CAPACITY,

       -- OTM Fleet
       CFA.ATTRIBUTE_CHAR9 AS OTM_FLEET,

       -- Fleet Type
       CFA.ATTRIBUTE_CHAR4 AS FLEET_TYPE,

       -- Power Unit
       CFA.ATTRIBUTE_CHAR10 AS POWER_UNIT,

       -- Asset End Date
       TO_CHAR(CFA.ACTIVE_END_DATE, 'DD-MM-YYYY') AS ASSET_END_DATE,

       -- Default Work Order Type
       CFA.DFLT_WO_TYPE,

       -- Item Number
       ITS.ITEM_NUMBER,

       -- Item Description
       ITS.DESCRIPTION AS ITEM_DES,

       -- Organization Name
       (
           SELECT ORGANIZATION_CODE
           FROM INV_ORG_PARAMETERS
           WHERE ORGANIZATION_ID = CFA.ITEM_ORGANIZATION_ID
       ) AS ORGANIZATION_NAME

FROM
       CSE_ASSETS_B CFA,
       CSE_ASSETS_TL FAT,
       EGP_SYSTEM_ITEMS_VL ITS

WHERE 1 = 1

      -- Language Filter
  AND FAT.LANGUAGE = 'US'

      -- Link Asset Base Table with Translation Table
  AND CFA.ASSET_ID = FAT.ASSET_ID

      -- Optional Asset Filter
      -- AND CFA.ASSET_NUMBER = 'FUR00118'

      -- Link Asset to Item Master
  AND ITS.INVENTORY_ITEM_ID = CFA.ITEM_ID

      -- Match Item Organization
  AND ITS.ORGANIZATION_ID = CFA.ITEM_ORGANIZATION_ID