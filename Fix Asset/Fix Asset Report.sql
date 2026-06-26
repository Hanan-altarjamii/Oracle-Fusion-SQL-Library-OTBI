/*
===============================================================================
Fix Asset Report
Author: Hanan Altarjami

Purpose:
    Retrieve Fixed Asset information linked to maintenance assets,
    including asset number, asset type, tag number, category, and
    fixed asset end date.

Tables Used:
    - CSE_ASSETS_B           (Maintenance Assets)
    - CSE_FA_ASSOCIATIONS    (Asset Associations)
    - FA_ADDITIONS_B         (Fixed Asset Master Data)
    - FA_CATEGORIES_B        (Fixed Asset Categories)

Report Output:
    - Asset ID
    - Fixed Asset Number
    - Asset Type
    - Tag Number
    - Category
    - Fixed Asset End Date

Parameters:
    - None

Notes:
    - Returns distinct asset records.
    - Asset category is displayed by concatenating category segments.

Module:
    Oracle Fusion SCM – Assets
===============================================================================
*/

SELECT DISTINCT

       FAA.ASSET_ID,

       -- Fixed Asset Number
       FAS.ASSET_NUMBER AS FIXED_ASSET_NUMBER,

       -- Asset Type
       FAS.ASSET_TYPE,

       -- Asset Tag Number
       FAS.TAG_NUMBER,

       -- Asset Category
       FAC.SEGMENT1 || ' ' ||
       FAC.SEGMENT2 || ' ' ||
       FAC.SEGMENT3 || ' ' ||
       FAC.SEGMENT4 AS CATEGORY,

       -- Fixed Asset End Date
       TO_CHAR(FAA.ACTIVE_END_DATE, 'DD-MM-YYYY') AS FIXED_ASSET_END_DATE

FROM
       CSE_ASSETS_B CFA,
       CSE_FA_ASSOCIATIONS FAA,
       FA_ADDITIONS_B FAS,
       FA_CATEGORIES_B FAC

WHERE 1 = 1

      -- Link Maintenance Asset to Asset Association
  AND FAA.ASSET_ID = CFA.ASSET_ID

      -- Link Asset Association to Fixed Asset
  AND FAA.FA_ASSET_ID = FAS.ASSET_ID

      -- Link Fixed Asset to Asset Category
  AND FAS.ASSET_CATEGORY_ID = FAC.CATEGORY_ID